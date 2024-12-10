# frozen_string_literal: true

module ActiveGraphql
  # GraphQL client which can be used to make requests to graphql endpoint
  #
  # Example usage:
  #   client = Client.new(url: 'http://example.com/graphql', headers: { 'Authorization' => 'secret'})
  #   client.query(:users).select(:name).result
  class Client
    require 'active_graphql/client/actions'
    require 'active_graphql/client/adapters'
    require 'active_graphql/client/response'

    attr_reader :config

    def initialize(config)
      @config = config.dup
      @adapter_class = @config.delete(:adapter)
    end

    def query(name)
      Actions::QueryAction.new(name:, client: adapter)
    end

    def mutation(name)
      Actions::MutationAction.new(name:, client: adapter)
    end

    def adapter
      @adapter ||= begin
        adapter_builder = @adapter_class || Adapters::GraphlientAdapter
        adapter_builder.new(config)
      end
    end
  end
end
