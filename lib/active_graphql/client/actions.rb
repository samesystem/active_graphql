# frozen_string_literal: true

module ActiveGraphql
  class Client
    # nodoc
    module Actions
      class WrongTypeError < ActiveGraphql::Error; end

      require 'active_graphql/client/actions/action'
      require 'active_graphql/client/actions/query_action'
      require 'active_graphql/client/actions/mutation_action'
    end
  end
end
