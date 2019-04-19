# frozen_string_literal: true

module ActiveGraphql
  class RelationProxy
    DEFAULT_BATCH_SIZE = 100

    delegate :each, :map, :empty?, :any?, to: :to_a

    def initialize(model, limit_number: nil, where_params: {}, offset_number: nil)
      @model = model
      @limit_number = limit_number
      @where_params = where_params
      @offset_number = offset_number
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

    def where(new_where_params)
      chain(where_params: where_params.merge(new_where_params.symbolize_keys))
    end

    def count
      @size = graphql_client
              .query(collection_resource_name.camelize(:lower))
              .select(:total)
              .result.total
    end

    def size
      @size ||= count
    end

    def find(id)
      params = graphql_client.query(model.graphql_resource_name.camelize(:lower))
                             .select(model.graphql_attributes)
                             .where(id: id)
                             .result.to_h

      model.new(params)
    end

    def last(number_of_items = 1)
      collection = collection_query(last: number_of_items)

      number_of_items == 1 ? collection.first : collection
    end

    def first(number_of_items = 1)
      collection = collection_query(first: number_of_items)

      number_of_items == 1 ? collection.first : collection
    end

    def pluck(*attributes)
      map do |item|
        attributes.map { |attribute| item.public_send(attribute) }
      end
    end

    def find_each(batch_size: DEFAULT_BATCH_SIZE)
      find_in_batches(batch_size: batch_size) do |items|
        items.each { |item| yield(item) }
      end
      self
    end

    def find_in_batches(batch_size: DEFAULT_BATCH_SIZE)
      offset_size = 0
      page_items = limit(batch_size).offset(offset_size).first_batch

      while page_items.any?
        yield(page_items)
        offset_size += batch_size
        page_items = limit(batch_size).offset(offset_size).first_batch
      end

      self
    end

    def to_a
      return @to_a if @to_a

      @to_a = []
      find_in_batches { |batch| @to_a += batch }
      @to_a
    end

    def first_batch
      @first_batch ||= collection_query(graphql_params)
    end

    def graphql_params
      camelized_filter = where_params.transform_keys { |key| key.to_s.camelize(:lower) }
      { filter: camelized_filter, first: limit_number, after: offset_number&.to_s }.compact
    end

    private

    attr_reader :model, :limit_number, :where_params, :offset_number

    def chain(
      limit_number: send(:limit_number),
      where_params: send(:where_params),
      offset_number: send(:offset_number)
    )
      self.class.new(model, limit_number: limit_number, where_params: where_params, offset_number: offset_number)
    end

    def graphql_client
      model.graphql_client
    end

    def collection_resource_name
      model.graphql_resource_name.to_s.underscore.pluralize
    end

    def formatted_query_params(params)
      params.map do |key, val|
        if val.is_a?(Hash)
          "#{key}: { #{formatted_query_params(val)} }"
        else
          "#{key}: #{val.inspect}"
        end
      end.join(', ')
    end

    def collection_query(query_params)
      raw_collection_query(query_params).map { |it| model.new(it) }
    end

    def graphql_collection_header(query_params)
      params = formatted_query_params(query_params)
      "#{collection_resource_name.camelize(:lower)}(#{params})"
    end

    def raw_collection_query(query_params)
      graphql_client.query(collection_resource_name)
                    .select(model.graphql_attributes)
                    .where(query_params)
                    .result.edges.map { |it| it.node.to_h }
    end
  end
end
