# frozen_string_literal: true

module ActiveGraphql
  module Errors
    class Error < StandardError; end
    class RecordNotFoundError < ActiveGraphql::Errors::Error; end
    class ResponseError < ActiveGraphql::Errors::Error; end
    class WrongTypeError < ActiveGraphql::Errors::Error; end
    class RecordNotValidError < ActiveGraphql::Errors::Error; end
  end
end
