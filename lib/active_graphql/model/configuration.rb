# frozen_string_literal: true

module ActiveGraphql
  module Model
    # stores all information for how to handle graphql requets for model
    class Configuration
      class Attribute
        attr_reader :name, :nesting, :decorate_with

        def initialize(name, nesting: nil, decorate_with: nil)
          @name = name.to_sym
          @nesting = nesting
          @decorate_with = decorate_with
        end

        def to_graphql_output
          nesting ? { name => nesting } : name
        end
      end

      def initialize
        @attributes = []
      end

      def initialize_copy(other)
        super
        @attributes = other.attributes.dup
        @graphql_client = other.graphql_client
        @url = other.url.dup
        @resource_name = other.resource_name.dup
        @resource_plural_name = other.resource_plural_name.dup
        @primary_key = :id
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
        list.each { |name| attribute(name) }
        detailed_attributes.each { |key, val| attribute(key, val) }
        @attributes
      end

      def attributes_graphql_output
        attributes.map(&:to_graphql_output)
      end

      def attribute(name, nesting = nil, decorate_with: nil)
        @attributes << Attribute.new(name, nesting: nesting, decorate_with: decorate_with)
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

      def primary_key(value = nil)
        update_or_return_config(:primary_key, value&.to_sym)
      end

      private

      def update_or_return_config(name, value)
        instance_variable_set("@#{name}", value) if value
        instance_variable_get("@#{name}")
      end
    end
  end
end
