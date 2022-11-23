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
          response = execute_request(
            document: document, operation_name: operation_name,
            variables: variables, context: context
          )
          response.body
        rescue Faraday::ClientError => e
          raise Graphlient::Errors::FaradayServerError, e
        end

        private

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
          @connection ||= Faraday.new(url: url, headers: headers) do |c|
            c.adapter Faraday::Response::RaiseError
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
