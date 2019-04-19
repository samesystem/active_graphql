# frozen_string_literal: true

module ActiveGraphql
  class Client
    module Adapters
      # Client which makes API requests to same_authorizer
      class GraphlientAdapter
        require 'graphlient'

        def initialize(config)
          @url = config[:url]
          @headers = config[:headers] || {}
        end

        def post(action)
          raw_response = graphql_client.query(action.to_graphql)
          Response.new(raw_response.data)
        rescue Graphlient::Errors::GraphQLError => e
          Response.new(nil, e)
        end

        private

        attr_reader :url, :headers

        def graphql_client
          @graphql_client ||= Graphlient::Client.new(url, headers: headers)
        end
      end
    end
  end
end
