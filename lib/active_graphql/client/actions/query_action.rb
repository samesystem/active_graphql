# frozen_string_literal: true

module ActiveGraphql
  class Client
    module Actions
      # handles all action details which are specific for query type request
      class QueryAction < Action
        def type
          :query
        end

        def find_by(inputs)
          where(inputs).result
        end

        def select_paginated(*array_outputs, **hash_outputs)
          outputs = join_array_and_hash(*array_outputs, **hash_outputs)
          select(edges: { node: outputs })
        end
      end
    end
  end
end
