# frozen_string_literal: true

module ActiveGraphql
  class Client
    # nodoc
    module Actions
      require 'active_graphql/errors'
      require 'active_graphql/client/actions/action'
      require 'active_graphql/client/actions/query_action'
      require 'active_graphql/client/actions/mutation_action'

      class WrongTypeError < ActiveGraphql::Errors::Error; end
    end
  end
end
