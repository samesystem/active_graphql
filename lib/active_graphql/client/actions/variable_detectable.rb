# frozen_string_literal: true

module ActiveGraphql
  class Client
    module Actions
      # handles all action details which are specific for query type request
      module VariableDetectable
        def variable_attributes(attributes)
          variables_or_nil = attributes.transform_values do |value|
            if value.is_a?(Hash)
              variable_attributes(value)
            elsif variable_value?(value)
              value
            elsif value.is_a?(Array)
              super_res = value.map.with_index { |val, i| [i, val] }.to_h
              variable_attributes(super_res)
            end
          end

          flatten_keys(variables_or_nil).select { |_, val| val.present? }
        end

        def variable_value?(value)
          kind_of_file?(value) || (value.is_a?(Array) && kind_of_file?(value.first))
        end

        private

        def flatten_keys(attributes, parent_key: nil)
          flattened = {}
          attributes.each do |key, value|
            full_key = [parent_key, key].compact.join('_').to_sym
            if value.is_a?(Hash)
              flattened.merge!(flatten_keys(value, parent_key: full_key))
            else
              flattened[full_key] = value
            end
          end
          flattened
        end

        def kind_of_file?(value)
          value.is_a?(File)
        end
      end
    end
  end
end
