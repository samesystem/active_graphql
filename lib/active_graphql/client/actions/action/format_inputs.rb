# frozen_string_literal: true

module ActiveGraphql
  class Client
    module Actions
      class Action
        # converts ruby object in to graphql input string
        class FormatInputs
          include VariableDetectable

          def initialize(inputs, client:)
            @inputs = inputs
            @client = client
          end

          def call
            return '' if inputs.empty?

            formatted(inputs)
          end

          private

          attr_reader :inputs, :client

          def treat_symbol_as_keyword?
            client.config[:treat_symbol_as_keyword]
          end

          def formatted(attributes, parent_keys: [])
            if attributes.is_a?(Hash)
              formatted_attributes(attributes, parent_keys:)
            else
              raise(
                ActiveGraphql::Client::Actions::WrongTypeError,
                "Unsupported attribute type: #{attributes.inspect}:#{attributes.class}"
              )
            end
          end

          def formatted_attributes(attributes, parent_keys: [])
            dup_attributes = attributes.dup
            keyword_fields = (dup_attributes.delete(:__keyword_attributes) || []).map(&:to_s)

            global_keyword_classes = treat_symbol_as_keyword? ? [Symbol] : []

            formatted_attributes = dup_attributes.map do |key, val|
              keyword_classes = keyword_fields.include?(key.to_s) ? [Symbol, String] : global_keyword_classes
              formatted_key_and_value(key, val, parent_keys:, keyword_classes:)
            end

            formatted_attributes.join(', ')
          end

          def formatted_key_and_value(key, value, parent_keys:, keyword_classes:)
            if variable_value?(value)
              "#{key}: $#{[*parent_keys, key].compact.join('_')}"
            else
              formatted_value = formatted_value_for(value, parent_keys: [*parent_keys, key], keyword_classes:)
              "#{key}: #{formatted_value}"
            end
          end

          def formatted_key_and_keyword(key, value, parent_keys:)
            if value.is_a?(String) || value.is_a?(Symbol)
              "#{key}: #{value}"
            else
              "#{key}: #{formatted_value(value, parent_keys: [*parent_keys, key])}"
            end
          end

          def formatted_value_for(value, parent_keys:, keyword_classes:) # rubocop:disable Metrics/MethodLength
            if value.is_a?(Hash)
              formatted_hash_value_for(value, parent_keys:)
            elsif value.is_a?(Array)
              formatted_array_value_for(value, parent_keys:, keyword_classes:)
            elsif value.nil?
              'null'
            elsif keyword_classes.any? { |klass| value.is_a?(klass) }
              value.to_s
            elsif value.is_a?(Symbol)
              value.to_s.inspect
            else
              value.inspect
            end
          end

          def formatted_array_value_for(value, parent_keys:, keyword_classes:)
            formatted_values = value.map.with_index do |it, idx|
              formatted_value_for(it, parent_keys: [*parent_keys, idx], keyword_classes:)
            end
            "[#{formatted_values.join(', ')}]"
          end

          def formatted_hash_value_for(value, parent_keys:)
            "{ #{formatted(value, parent_keys:)} }"
          end
        end
      end
    end
  end
end
