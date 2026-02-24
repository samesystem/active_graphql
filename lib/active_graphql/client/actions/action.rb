# frozen_string_literal: true

require 'active_graphql/client/actions/variable_detectable'
require 'active_graphql/client/actions/action/format_outputs'
require 'active_graphql/client/actions/action/format_inputs'
require 'active_graphql/client/actions/action/format_variable_inputs'

module ActiveGraphql
  class Client
    module Actions
      # Base class for query/mutation action objects
      class Action
        include VariableDetectable

        class InvalidActionError < StandardError; end

        attr_reader :name, :type, :output_values, :client, :input_attributes, :meta_attributes

        delegate :result, :result!, to: :response

        def initialize(name:, client:, output_values: [], input_attributes: {}, meta_attributes: {})
          @name = name
          @output_values = output_values
          @input_attributes = input_attributes
          @meta_attributes = meta_attributes
          @client = client
        end

        def inspect
          "#<#{self.class} " \
            "name: #{name.inspect}, " \
            "input: #{input_attributes.inspect}, " \
            "output: #{output_values.inspect}, " \
            "meta: #{meta_attributes.inspect}" \
            '>'
        end

        def rewhere(**input_attributes)
          chain(input_attributes:)
        end

        def where(**extra_input_attributes)
          rewhere(**input_attributes, **extra_input_attributes)
        end
        alias input where

        def response
          @response ||= client.post(self)
        end

        def meta(new_attributes)
          chain(meta_attributes: meta_attributes.merge(new_attributes))
        end

        def reselect(*array_outputs, **hash_outputs)
          outputs = join_array_and_hash(*array_outputs, **hash_outputs)
          chain(output_values: outputs)
        end

        def select(*array_outputs, **hash_outputs)
          full_array_outputs = (output_values + array_outputs).uniq
          reselect(*full_array_outputs, **hash_outputs)
        end
        alias output select

        def to_graphql
          assert_format

          <<~TXT
            #{type}#{wrapped_header formatted_variable_headers} {
              #{name}#{wrapped_header formatted_inputs} {
                #{formatted_outputs}
              }
            }
          TXT
        end

        def graphql_variables
          variable_attributes(input_attributes)
        end

        private

        def join_array_and_hash(*array, **hash)
          array + hash.map { |k, v| { k => v } }
        end

        def formatted_inputs
          FormatInputs.new(input_attributes, client:).call
        end

        def formatted_outputs
          FormatOutputs.new(output_values).call
        end

        def formatted_variable_headers
          FormatVariableInputs.new(graphql_variables).call
        end

        def assert_format
          return unless output_values.empty?

          raise(
            InvalidActionError,
            'at least one return value must be set. Do `query.select(:fields_to_return)` to do so'
          )
        end

        def chain(**new_values)
          self.class.new(
            name:,
            output_values:,
            input_attributes:,
            meta_attributes:,
            client:,
            **new_values
          )
        end

        def wrapped_header(header_text)
          return '' if header_text.empty?

          "(#{header_text})"
        end
      end
    end
  end
end
