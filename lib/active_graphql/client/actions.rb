# frozen_string_literal: true

module ActiveGraphql
  class Client
    # nodoc
    module Actions
      class WrongTypeError < ActiveGraphql::Error; end

      autoload :MutationAction, 'active_graphql/client/actions/query_action'
      autoload :QueryAction, 'active_graphql/client/actions/mutation_action'
      autoload :Action, 'active_graphql/client/actions/action'
    end
  end
end
