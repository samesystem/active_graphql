# frozen_string_literal: true

module ActiveGraphql
  class Client
    module Adapters
      # Client which makes raw API requests to GraphQL server
      class GraphlientAdapter
        require 'graphlient'
        require_relative './graphlient_multipart_adapter'

        def initialize(config)
          @url = config[:url]
          @config = config
        end

        def post(action)
          raw_response = graphql_client.query(action.to_graphql, action.graphql_variables)
          Response.new(raw_response.data)
        rescue Graphlient::Errors::GraphQLError => e
          Response.new(nil, e)
        end

        def adapter_config
          @adapter_config ||= config.except(:url, :multipart).tap do |new_config|
            new_config[:http] = GraphlientMultipartAdapter if multipart?
          end
        end

        private

        attr_reader :url, :config

        def graphql_client
          @graphql_client ||= Graphlient::Client.new(url, **adapter_config)
        end

        def multipart?
          config[:multipart].present?
        end
      end
    end
  end
end
