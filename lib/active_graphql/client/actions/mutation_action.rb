# frozen_string_literal: true

module ActiveGraphql
  class Client
    module Actions
      # handles all action details which are specific for mutation type request
      class MutationAction < Action
        require 'active_graphql/errors'

        class UnsuccessfullRequestError < ActiveGraphql::Errors::Error; end

        def type
          :mutation
        end

        def update(inputs)
          where(inputs).response
        end

        def update!(inputs)
          response = where(inputs).response
          return response.result if response.success?

          raise UnsuccessfullRequestError, response.errors.first
        end
      end
    end
  end
end
