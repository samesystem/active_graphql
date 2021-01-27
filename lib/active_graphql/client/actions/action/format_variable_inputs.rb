# frozen_string_literal: true

module ActiveGraphql
  class Client
    module Actions
      class Action
        # converts ruby object in to varbiable stype grapqhl input
        class FormatVariableInputs
          include VariableDetectable

          def initialize(inputs)
            @initial_inputs = inputs
          end

          def call
            return '' if inputs.empty?

            formatted_attributes(inputs)
          end

          private

          attr_reader :initial_inputs

          def formatted_attributes(attributes)
            attributes = attributes.dup
            formatted_attributes = attributes.map do |key, val|
              formatted_key_and_type(key, val)
            end

            formatted_attributes.join(', ')
          end

          def inputs
            @inputs ||= variable_attributes(initial_inputs)
          end

          def formatted_key_and_type(key, value)
            "$#{key}: #{formatted_type(value)}"
          end

          def formatted_type(value)
            if value.is_a?(Array)
              '[File!]!'
            else
              'File!'
            end
          end
        end
      end
    end
  end
end
