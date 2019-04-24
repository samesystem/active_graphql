# frozen_string_literal: true

module ActiveGraphql
  class Client
    module Actions
      class Action
        # converts ruby object in to grapqhl output string
        class FormatOutputs
          def initialize(outputs)
            @outputs = outputs
          end

          def call
            Array.wrap(outputs).map { |it| formatted(it) }.join(', ')
          end

          private

          attr_reader :outputs

          def formatted(attribute) # rubocop:disable Metrics/MethodLength
            case attribute
            when Hash
              attribute.map { |key, value| "#{key} { #{formatted(value)} }" }.join(', ')
            when Symbol, String
              attribute.to_s
            when Array
              attribute.map { |it| formatted(it) }.join(', ')
            else
              raise(
                ActiveGraphql::Client::Actions::WrongTypeError,
                "Unsupported attribute type: #{attribute.inspect}:#{attribute.class}"
              )
            end
          end
        end
      end
    end
  end
end
