# frozen_string_literal: true

module ActiveGraphql
  # GraphQL client which can be used to make requests to graphql endpoint
  #
  # Example usage:
  #   client = Client.new(url: 'http://example.com/graphql', headers: { 'Authorization' => 'secret'})
  #   client.query(:users).select(:name).result
  class Client
    autoload :Actions, 'active_graphql/client/actions'
    autoload :Adapters, 'active_graphql/client/adapters'
    autoload :Response, 'active_graphql/client/response'

    def initialize(config)
      @config = config.dup
      @adapter = @config.delete(:adapter)
    end

    def query(name)
      Actions::QueryAction.new(name: name, client: adapter)
    end

    def mutation(name)
      Actions::MutationAction.new(name: name, client: adapter)
    end

    def adapter
      @adapter ||= Adapters::GraphlientAdapter.new(config)
    end

    private

    attr_reader :config
  end
end
