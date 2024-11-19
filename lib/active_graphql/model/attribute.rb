# frozen_string_literal: true

module ActiveGraphql
  module Model
    # stores attribute information for how to handle graphql requests for model
    class Attribute
      attr_reader :name, :nesting, :decorate_with

      def initialize(name, nesting: nil, decorate_with: nil, keyword: false)
        @name = name.to_sym
        @nesting = nesting
        @decorate_with = decorate_with
        @keyword = keyword || false
      end

      def keyword?
        @keyword
      end

      def to_graphql_output
        nesting ? { name => nesting } : name
      end
    end
  end
end
