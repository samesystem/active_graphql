# frozen_string_literal: true

module ActiveGraphql
  class Client
    module Adapters
      # Client which makes raw API requests to GraphQL server
      class GraphlientAdapter
        require 'graphlient'

        def initialize(config)
          @url = config[:url]
          @adapter_config = config.except(:url)
        end

        def post(action)
          raw_response = graphql_client.query(action.to_graphql)
          Response.new(raw_response.data)
        rescue Graphlient::Errors::GraphQLError => e
          Response.new(nil, e)
        end

        private

        attr_reader :url, :adapter_config

        def graphql_client
          @graphql_client ||= Graphlient::Client.new(url, **adapter_config)
        end
      end
    end
  end
end
