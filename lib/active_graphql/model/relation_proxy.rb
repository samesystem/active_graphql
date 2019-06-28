# frozen_string_literal: true

module ActiveGraphql
  module Model
    # transforms all AR-like queries in to graphql requests
    class RelationProxy # rubocop:disable Metrics/ClassLength
      require 'active_support/core_ext/module/delegation'
      require 'active_graphql/model/find_in_batches'

      DEFAULT_BATCH_SIZE = 100

      include Enumerable

      delegate :each, :map, to: :to_a

      def initialize(model, limit_number: nil, where_attributes: {}, offset_number: nil, meta_attributes: {}, order_attributes: {})
        @model = model
        @limit_number = limit_number
        @where_attributes = where_attributes
        @offset_number = offset_number
        @meta_attributes = meta_attributes
        @order_attributes = order_attributes
      end

      def all
        self
      end

      def limit(limit_number)
        chain(limit_number: limit_number)
      end

      def offset(offset_number)
        chain(offset_number: offset_number)
      end

      def where(new_where_attributes)
        chain(where_attributes: where_attributes.merge(new_where_attributes.symbolize_keys))
      end

      def meta(new_meta_attributes)
        chain(meta_attributes: meta_attributes.merge(new_meta_attributes.symbolize_keys))
      end

      def page(page_number = nil, per_page: 100)
        page_number = [page_number.to_i, 1].max
        offset = (page_number - 1) * per_page
        limit(per_page).offset(offset).meta(current_page: page_number, per_page: per_page)
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
          graphql_client.query(resource_name).select(*config.attributes_graphql_output).where(id: id)
        )

        response = action.response
        raise RecordNotFoundError unless action.response.result

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

      def find_each(batch_size: DEFAULT_BATCH_SIZE)
        find_in_batches(batch_size: batch_size) do |items|
          items.each { |item| yield(item) }
        end
        self
      end

      def find_in_batches(*args, &block)
        FindInBatches.call(meta(paginated: true), *args, &block)
      end

      def to_a
        return @to_a if @to_a

        @to_a = []
        find_in_batches { |batch| @to_a += batch }
        @to_a
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

      def order(order_params)
        if order_params.is_a?(Hash)
          order_by = order_params.keys.first
          direction = order_params.values.first
        else
          order_by = order_params
          direction = :asc
        end

        return chain(order_attributes: {}) if order_by.to_s.empty?

        chain(
          order_attributes: {
            by: order_by.to_s.upcase,
            direction: direction.to_s.upcase,
            __keyword_attributes: %i[by direction]
          }
        )
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

      private

      attr_reader :model, :limit_number, :where_attributes, :offset_number, :meta_attributes, :order_attributes

      def formatted_raw_response
        @formatted_raw_response ||= formatted_raw.response
      end

      def raw
        @raw ||= begin
          graphql_client
            .query(resource_plural_name)
            .meta(meta_attributes)
            .select(config.attributes_graphql_output)
            .where(graphql_params)
        end
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

      def chain(
        limit_number: send(:limit_number),
        where_attributes: send(:where_attributes),
        meta_attributes: send(:meta_attributes),
        offset_number: send(:offset_number),
        order_attributes: send(:order_attributes)
      )
        self.class.new(
          model,
          limit_number: limit_number,
          where_attributes: where_attributes,
          meta_attributes: meta_attributes,
          offset_number: offset_number,
          order_attributes: order_attributes
        )
      end

      def graphql_client
        config.graphql_client
      end

      def config
        model.active_graphql
      end
    end
  end
end
