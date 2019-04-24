# frozen_string_literal: true

module ActiveGraphql
  class Client
    # graphql response wrapper
    class Response
      attr_reader :graphql_object

      def initialize(graphql_object, error = nil)
        if graphql_object
          root_field = graphql_object.to_h.keys.first.to_s.underscore
          @graphql_object = graphql_object.public_send(root_field) if graphql_object
        end

        @graphql_error = error if error
      end

      def result
        graphql_object
      end

      def result!
        raise ResponseError, errors.first if errors.any?

        graphql_object
      end

      def success?
        graphql_error.nil?
      end

      def errors
        return [] if graphql_error.nil?

        graphql_error.errors.to_h.values
      end

      private

      attr_reader :graphql_error
    end
  end
end
