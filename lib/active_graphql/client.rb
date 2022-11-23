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

    def initialize(config)
      @config = config.dup
      @adapter_class = @config.delete(:adapter)
    end

    def query(name)
      Actions::QueryAction.new(name: name, client: adapter)
    end

    def mutation(name)
      Actions::MutationAction.new(name: name, client: adapter)
    end

    def adapter
      @adapter ||= begin
        adapter_builder = @adapter_class || Adapters::GraphlientAdapter
        adapter_builder.new(config)
      end
    end

    def self.dump_schema(schema, io = nil, context: {})
      unless schema.respond_to?(:execute)
        raise TypeError, "expected schema to respond to #execute(), but was #{schema.class}"
      end

      result = JSON.parse(schema.execute(
        document: IntrospectionDocument,
        operation_name: "IntrospectionQuery",
        variables: {},
        context: context
      ))

      if io
        io = File.open(io, "w") if io.is_a?(String)
        io.write(JSON.pretty_generate(result))
        io.close_write
      end

      result
    end

    private

    attr_reader :config
  end
end
