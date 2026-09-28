# frozen_string_literal: true

require 'graphlient'
require 'faraday'
require 'faraday/multipart'
require 'active_graphql/client/adapters/format_multipart_variables'

module ActiveGraphql
  class Client
    module Adapters
      # Adapter enabling multipart data transfer
      class GraphlientMultipartAdapter < Graphlient::Adapters::HTTP::Adapter
        def execute(document:, operation_name:, variables:, context:)
          response = execute_request(document:, operation_name:, variables:, context:)
          raise_server_error(response) if response.status >= 500

          response.body
        rescue Faraday::ClientError, Faraday::ServerError => e
          raise Graphlient::Errors::FaradayServerError, e
        end

        private

        # 4xx bodies may still carry GraphQL errors, so only 5xx are treated as transport failures.
        def raise_server_error(response)
          raise Faraday::ServerError.new("the server responded with status #{response.status}", response.to_hash)
        end

        def execute_request(document:, operation_name:, variables:, context:)
          connection.post do |req|
            req.headers.merge!(context[:headers] || {})
            req.body = {
              query: document.to_query_string,
              operationName: operation_name,
              variables: FormatMultipartVariables.new(variables).call
            }
          end
        end

        def connection
          @connection ||= Faraday.new(url:, headers:) do |c|
            c.request :multipart
            c.request :url_encoded
            c.response :json

            block_given? ? yield(c) : c.adapter(Faraday::Adapter::NetHttp)
          end
        end
      end
    end
  end
end
