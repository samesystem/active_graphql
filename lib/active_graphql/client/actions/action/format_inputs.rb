# frozen_string_literal: true

module ActiveGraphql
  class Client
    module Actions
      class Action
        # converts ruby object in to grapqhl input string
        class FormatInputs
          include VariableDetectable

          def initialize(inputs)
            @inputs = inputs
          end

          def call
            return '' if inputs.empty?

            formatted(inputs)
          end

          private

          attr_reader :inputs

          def formatted(attributes, parent_keys: [])
            if attributes.is_a?(Hash)
              formatted_attributes(attributes, parent_keys: parent_keys)
            else
              raise(
                ActiveGraphql::Client::Actions::WrongTypeError,
                "Unsupported attribute type: #{attributes.inspect}:#{attributes.class}"
              )
            end
          end

          def formatted_attributes(attributes, parent_keys: [])
            attributes = attributes.dup
            keyword_fields = (attributes.delete(:__keyword_attributes) || []).map(&:to_s)

            formatted_attributes = attributes.map do |key, val|
              if keyword_fields.include?(key.to_s)
                formatted_key_and_keyword(key, val, parent_keys: parent_keys)
              else
                formatted_key_and_value(key, val, parent_keys: parent_keys)
              end
            end

            formatted_attributes.join(', ')
          end

          def formatted_key_and_value(key, value, parent_keys:)
            if variable_value?(value)
              "#{key}: $#{[*parent_keys, key].compact.join('_')}"
            else
              "#{key}: #{formatted_value(value, parent_keys: [*parent_keys, key])}"
            end
          end

          def formatted_key_and_keyword(key, value, parent_keys:)
            if value.is_a?(String) || value.is_a?(Symbol)
              "#{key}: #{value}"
            else
              "#{key}: #{formatted_value(value, parent_keys: [*parent_keys, key])}"
            end
          end

          def formatted_value(value, parent_keys:) # rubocop:disable Metrics/MethodLength
            case value
            when Hash
              "{ #{formatted(value, parent_keys: parent_keys)} }"
            when Array
              formatted_values = value.map.with_index do |it, idx|
                formatted_value(it, parent_keys: [*parent_keys, idx])
              end
              "[#{formatted_values.join(', ')}]"
            when nil
              'null'
            when Symbol
              value.to_s.inspect
            else
              value.inspect
            end
          end
        end
      end
    end
  end
end
