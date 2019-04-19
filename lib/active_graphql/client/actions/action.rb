# frozen_string_literal: true

module ActiveGraphql
  class Client
    module Actions
      # Base class for query/mutation action objects
      class Action
        class InvalidActionError < StandardError; end

        autoload :FormatOutputs, 'active_graphql/client/actions/action/format_outputs'
        autoload :FormatInputs, 'active_graphql/client/actions/action/format_inputs'

        attr_reader :name, :type, :output_values, :client, :input_attributes

        def initialize(name:, client:, output_values: [], input_attributes: {})
          @name = name
          @output_values = output_values
          @input_attributes = input_attributes
          @client = client
        end

        def where(**input_attributes)
          chain(input_attributes: input_attributes)
        end
        alias input where

        def result
          response.graphql_object
        end

        def response
          client.post(self)
        end

        def select(*array_outputs, **hash_outputs)
          outputs = join_array_and_hash(*array_outputs, **hash_outputs)
          chain(output_values: outputs)
        end
        alias output select

        def to_graphql
          assert_format

          <<~TXT
            #{type} {
              #{name}#{wrapped_header formatted_inputs} {
                #{formatted_outputs}
              }
            }
          TXT
        end

        private

        def join_array_and_hash(*array, **hash)
          array + hash.map { |k, v| { k => v } }
        end

        def formatted_inputs
          FormatInputs.new(input_attributes).call
        end

        def formatted_outputs
          FormatOutputs.new(output_values).call
        end

        def assert_format
          if output_values.empty?
            raise(
              InvalidActionError,
              'at least one return value must be set. Do `query.select(:fields_to_return)` to do so'
            )
          end
        end

        def chain(**new_values)
          self.class.new(
            name: name,
            output_values: output_values,
            input_attributes: input_attributes,
            client: client,
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
