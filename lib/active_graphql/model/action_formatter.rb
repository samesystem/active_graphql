# frozen_string_literal: true

module ActiveGraphql
  module Model
    # reformats action to default format which very opinionated and based in following assumptions:
    # * all attributes and fields are camel cased
    # * all mutation actions accept one or two fields: id and input (input is everyting except 'id')
    # * collection actions are paginated and accepts input attribute `filter`
    #
    # github graphql structure was used as inspiration
    class ActionFormatter
      require 'active_support/core_ext/string'

      def self.call(action)
        new(action).call
      end

      def initialize(action)
        @action = action
      end

      def call
        action.class.new(
          name: formatted_name,
          client: action.client,
          output_values: formatted_outputs,
          input_attributes: formatted_inputs.symbolize_keys
        )
      end

      private

      attr_reader :action

      def formatted_name
        action.name.camelize(:lower)
      end

      def formatted_inputs
        attributes = action.input_attributes.deep_transform_keys do |key|
          key.to_s.starts_with?('__') ? key : key.to_s.camelize(:lower)
        end

        if mutation?
          {
            'input' => attributes.except('id').presence,
            'id' => attributes['id']
          }.compact
        else
          attributes
        end
      end

      def mutation?
        action.type == :mutation
      end

      def paginated?
        action.meta_attributes[:paginated]
      end

      def formatted_outputs
        outputs = formatted_output_values(action.output_values)

        if paginated?
          {
            edges: { node: outputs },
            pageInfo: [:hasNextPage]
          }
        else
          outputs.is_a?(Hash) ? outputs.symbolize_keys : outputs
        end
      end

      def formatted_output_values(attributes)
        if attributes.is_a?(Array)
          attributes.map { |it| formatted_output_values(it) }
        elsif attributes.is_a?(Hash)
          attributes
            .transform_keys { |key| formatted_output_values(key) }
            .transform_values { |value| formatted_output_values(value) }
        else
          attributes.to_s.camelize(:lower)
        end
      end
    end
  end
end
