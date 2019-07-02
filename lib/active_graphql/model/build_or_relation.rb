# frozen_string_literal: true

module ActiveGraphql
  module Model
    # reformats action to default format which very opinionated and based in following assumptions:
    # * all attributes and fields are camel cased
    # * all mutation actions accept one or two fields: id and input (input is everyting except 'id')
    # * collection actions are paginated and accepts input attribute `filter`
    #
    # github graphql structure was used as inspiration
    class BuildOrRelation
      def self.call(*args)
        new(*args).call
      end

      def initialize(left_scope, right_scope)
        @left_scope = left_scope
        @right_scope = right_scope
      end

      def call
        shared_scope.where(or: or_attributes)
      end

      private

      attr_reader :left_scope, :right_scope

      def shared_scope
        @shared_scope ||= clean_scope.where(shared_attributes)
      end

      def clean_scope
        left_scope.where_attributes.keys.reduce(left_scope) { |final, key| final.unscope(where: key) }
      end

      def shared_attributes
        @shared_attributes ||= begin
          left_attributes = left_scope.where_attributes
          right_attributes = right_scope.where_attributes
          left_attributes.select { |key, value| right_attributes.key?(key) && right_attributes[key] == value }
        end
      end

      def or_attributes
        left_unique_attributes.merge(right_unique_attributes) { |_key, old_value, new_value| [*old_value, new_value] }
      end

      def left_unique_attributes
        left_or_attributes = left_scope.where_attributes[:or] || {}

        unique_attributes = left_scope.where_attributes.except(:or).select do |key, value|
          !shared_attributes.key?(key) || shared_attributes[key] != value
        end

        left_or_attributes.merge(unique_attributes)
      end

      def right_unique_attributes
        right_scope.where_attributes.select do |key, value|
          !shared_attributes.key?(key) || shared_attributes[key] != value
        end
      end
    end
  end
end
