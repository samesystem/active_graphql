# frozen_string_literal: true

module ActiveGraphql
  class Client
    module Actions
      class Action
        # converts ruby object in to grapqhl input string
        class FormatInputs
          def initialize(inputs)
            @inputs = inputs
          end

          def call
            return '' if inputs.empty?

            formatted(inputs)
          end

          private

          attr_reader :inputs

          def formatted(attributes)
            if attributes.is_a?(Hash)
              formatted_attributes(attributes)
            else
              raise(
                ActiveGraphql::Client::Actions::WrongTypeError,
                "Unsupported attribute type: #{attributes.inspect}:#{attributes.class}"
              )
            end
          end

          def formatted_attributes(attributes)
            attributes = attributes.dup
            keyword_fields = (attributes.delete(:__keyword_attributes) || []).map(&:to_s)

            formatted_attributes = attributes.map do |key, val|
              if keyword_fields.include?(key.to_s)
                formatted_key_and_keyword(key, val)
              else
                formatted_key_and_value(key, val)
              end
            end

            formatted_attributes.join(', ')
          end

          def formatted_key_and_value(key, value)
            "#{key}: #{formatted_value(value)}"
          end

          def formatted_key_and_keyword(key, value)
            if value.is_a?(String) || value.is_a?(Symbol)
              "#{key}: #{value}"
            else
              "#{key}: #{formatted_value(value)}"
            end
          end

          def formatted_value(value) # rubocop:disable Metrics/MethodLength
            case value
            when Hash
              "{ #{formatted(value)} }"
            when Array
              formatted_values = value.map { |it| formatted_value(it) }
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
