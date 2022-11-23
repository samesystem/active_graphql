# frozen_string_literal: true

module ActiveGraphql
  module Model
    # fetches graphql paginated records in batches
    class FindInBatches
      def self.call(*args, **kwargs, &block)
        new(*args, **kwargs).call(&block)
      end

      def initialize(relation, batch_size: 100, fetched_items_count: 0)
        @relation = relation
        @batch_size = batch_size
        @fetched_items_count = fetched_items_count
      end

      def call(&block)
        scope = relation.limit(batch_size).offset(offset_size)

        items = scope.first_batch
        return nil if items.empty?

        yield(items)
        fetch_next_batch(items_count: items.count, &block) if scope.next_page?
      end

      private

      attr_reader :relation, :fetched_items_count

      def fetch_next_batch(items_count:, &block)
        self.class.call(
          relation,
          batch_size: batch_size,
          fetched_items_count: fetched_items_count + items_count,
          &block
        )
      end

      def offset_size
        relation.send(:offset_number).to_i + fetched_items_count
      end

      def batch_size
        items_to_fetch = collection_limit_number - fetched_items_count if collection_limit_number
        [@batch_size, collection_limit_number, items_to_fetch].compact.min
      end

      def collection_limit_number
        relation.send(:limit_number)
      end
    end
  end
end
