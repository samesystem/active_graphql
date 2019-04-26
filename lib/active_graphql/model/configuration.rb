# frozen_string_literal: true

module ActiveGraphql
  module Model
    # stores all information for how to handle graphql requets for model
    class Configuration
      def initialize_copy(other)
        super
        @attributes = other.attributes.dup
        @graphql_client = other.graphql_client
        @url = other.url.dup
        @resource_name = other.resource_name.dup
        @resource_plural_name = other.resource_plural_name.dup
      end

      def graphql_client(client = nil)
        @graphql_client = client if client
        @graphql_client ||= ActiveGraphql::Client.new(url: url)
      end

      def formatter(new_formatter = nil, &block)
        @formatter = new_formatter || block if new_formatter || block
        @formatter ||= Model::ActionFormatter
      end

      def attributes(*list, **detailed_attributes)
        @attributes ||= []
        @attributes += list
        @attributes += detailed_attributes.map(&:to_h)
      end

      def url(value = nil)
        update_or_return_config(:url, value)
      end

      def resource_name(value = nil)
        update_or_return_config(:resource_name, value)
      end

      def resource_plural_name(value = nil)
        update_or_return_config(:resource_plural_name, value)
      end

      private

      def update_or_return_config(name, value)
        instance_variable_set("@#{name}", value) if value
        instance_variable_get("@#{name}")
      end
    end
  end
end
