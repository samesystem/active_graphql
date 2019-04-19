# frozen_string_literal: true

class ActiveGraphql::Client::Actions::Action
  class FormatOutputs
    def initialize(outputs)
      @outputs = outputs
    end

    def call
      outputs.map { |it| formatted(it) }.join(', ')
    end

    private

    attr_reader :outputs

    def formatted(attribute)
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
