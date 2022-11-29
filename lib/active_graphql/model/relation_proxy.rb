# frozen_string_literal: true

module ActiveGraphql
  module Model
    # transforms all AR-like queries in to graphql requests
    class RelationProxy # rubocop:disable Metrics/ClassLength
      require 'active_support/core_ext/module/delegation'
      require 'active_graphql/model/find_in_batches'
      require 'active_graphql/model/build_or_relation'
      require 'active_graphql/errors'

      DEFAULT_BATCH_SIZE = 100

      include Enumerable

      attr_reader :where_attributes, :output_values

      delegate :each, :map, to: :to_a

      def initialize(model, **params)
        @model = model
        @limit_number = params[:limit_number]
        @where_attributes = params[:where_attributes] || {}
        @offset_number = params[:offset_number]
        @meta_attributes = params[:meta_attributes] || {}
        @order_attributes = params[:order_attributes] || []
        @output_values = params[:output_values] || []
      end

      def all
        self
      end

      def limit(limit_number)
        chain(limit_number:)
      end

      def offset(offset_number)
        chain(offset_number:)
      end

      def where(new_where_attributes)
        chain(where_attributes: where_attributes.deep_merge(new_where_attributes.symbolize_keys))
      end

      def select(*array_outputs, **hash_outputs)
        full_array_outputs = (output_values + array_outputs).uniq
        reselect(*full_array_outputs, **hash_outputs)
      end

      def reselect(*array_outputs, **hash_outputs)
        outputs = join_array_and_hash(*array_outputs, **hash_outputs)
        chain(output_values: outputs)
      end

      def select_attributes
        output_values.presence || config.attributes_graphql_output
      end

      def merge(other_query)
        where(other_query.where_attributes)
      end

      def unscope(where:)
        chain(where_attributes: where_attributes.except(where))
      end

      def meta(new_meta_attributes)
        chain(meta_attributes: meta_attributes.merge(new_meta_attributes.symbolize_keys))
      end

      def page(page_number = 1)
        paginate(page: page_number)
      end

      def paginate(page: nil, per_page: 100)
        page_number = [page.to_i, 1].max
        offset = (page_number - 1) * per_page
        limit(per_page).offset(offset).meta(current_page: page_number, per_page:)
      end

      def current_page
        meta_attributes.fetch(:current_page, 1)
      end

      def total_pages
        last_page = (total.to_f / meta_attributes.fetch(:per_page, 100)).ceil
        [last_page, 1].max
      end

      def count
        @size = begin
          total_without_offset = [total - offset_number.to_i].max
          [total_without_offset, limit_number].compact.min
        end
      end

      def total
        formatted_raw.reselect(:total).result.total
      end

      def size
        @size ||= count
      end

      def find(id) # rubocop:disable Metrics/AbcSize
        action = formatted_action(
          graphql_client
            .query(resource_name)
            .select(*select_attributes)
            .where(config.primary_key => id)
        )

        response = action.response
        raise Errors::RecordNotFoundError unless action.response.result

        model.new(response.result!.to_h)
      end

      def last(number_of_items = 1)
        paginated_raw = formatted_action(raw.meta(paginated: true))
        result = paginated_raw.where(last: number_of_items).result!
        collection = decorate_paginated_result(result)

        number_of_items == 1 ? collection.first : collection
      end

      def first(number_of_items = 1)
        paginated_raw = formatted_action(raw.meta(paginated: true))
        result = paginated_raw.where(first: number_of_items).result!
        collection = decorate_paginated_result(result)

        number_of_items == 1 ? collection.first : collection
      end

      def pluck(*attributes)
        map do |record|
          if attributes.count > 1
            attributes.map { |attribute| record.public_send(attribute) }
          else
            record.public_send(attributes.first)
          end
        end
      end

      def find_each(batch_size: DEFAULT_BATCH_SIZE, &block)
        find_in_batches(batch_size:) do |items|
          items.each(&block)
        end
        self
      end

      def find_in_batches(*args, **kwargs, &block)
        FindInBatches.call(meta(paginated: true), *args, **kwargs, &block)
      end

      def to_a
        return @to_a if defined?(@to_a)

        list = []
        find_in_batches { |batch| list += batch }

        @to_a = list
      end

      def next_page?
        raw_result.page_info.has_next_page
      end

      def first_batch
        @first_batch ||= decorate_paginated_result(formatted_raw_response.result!)
      end

      def raw_result
        formatted_raw_response.result
      end

      def graphql_params
        {
          filter: where_attributes.presence,
          order: order_attributes.presence,
          first: limit_number,
          after: offset_number&.to_s
        }.compact
      end

      def to_graphql
        formatted_action(raw.meta(paginated: true)).to_graphql
      end

      def order(*order_params)
        chain(order_attributes: order_params_attributes(order_params))
      end

      def order_params_attributes(order_params)
        send(:order_attributes) + order_params
                                  .compact
                                  .flat_map { |order_param| ordering_attributes(order_param) }
                                  .select(&:compact)
      end

      def ordering_attributes(order_param)
        if order_param.is_a?(Hash)
          order_param.map { |param, direction| order_param_attributes(param, direction) }
        else
          order_param_attributes(order_param, :asc)
        end
      end

      def order_param_attributes(order_by, direction)
        {
          by: order_by&.to_s&.upcase,
          direction: direction&.to_s&.upcase,
          __keyword_attributes: %i[by direction]
        }
      end

      def empty?
        count.zero?
      end

      def blank?
        empty?
      end

      def present?
        !blank?
      end

      def or(relation)
        BuildOrRelation.call(self, relation)
      end

      def respond_to_missing?(method_name, *args, &block)
        model.respond_to?(method_name) || super
      end

      def method_missing(method_name, *args, &block)
        if model.respond_to?(method_name)
          merge(model.public_send(method_name, *args, &block))
        else
          super
        end
      end

      private

      attr_reader :model, :limit_number, :offset_number, :meta_attributes, :order_attributes

      def formatted_raw_response
        @formatted_raw_response ||= formatted_raw.response
      end

      def raw
        @raw ||= graphql_client
                 .query(resource_plural_name)
                 .meta(meta_attributes)
                 .select(select_attributes)
                 .where(**graphql_params)
      end

      def formatted_action(action)
        config.formatter.call(action)
      end

      def formatted_raw
        formatted_action(raw)
      end

      def decorate_paginated_result(result)
        result.edges.map { |it| model.new(it.node.to_h) }
      end

      def resource_plural_name
        @resource_plural_name ||= begin
          name = config.resource_plural_name&.to_s || resource_name.pluralize
          name
        end
      end

      def resource_name
        @resource_name ||= begin
          name = config.resource_name&.to_s || model.name.demodulize
          name
        end
      end

      def chain( # rubocop:disable Metrics/ParameterLists
        limit_number: send(:limit_number),
        where_attributes: send(:where_attributes),
        meta_attributes: send(:meta_attributes),
        offset_number: send(:offset_number),
        order_attributes: send(:order_attributes),
        output_values: send(:output_values)
      )
        self.class.new(
          model,
          limit_number:,
          where_attributes:,
          meta_attributes:,
          offset_number:,
          order_attributes:,
          output_values:
        )
      end

      def graphql_client
        config.graphql_client
      end

      def config
        model.active_graphql
      end

      def join_array_and_hash(*array, **hash)
        array + hash.map { |k, v| { k => v } }
      end
    end
  end
end
