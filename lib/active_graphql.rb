# frozen_string_literal: true

require 'active_graphql/version'

# nodoc
module ActiveGraphql
  class Error < StandardError; end
  class ResponseError < ActiveGraphql::Error; end
  class WrongTypeError < ActiveGraphql::Error; end
  class RecordNotValidError < ActiveGraphql::Error; end

  require 'active_support/core_ext/module/delegation'
  require 'active_graphql/client'
  require 'active_graphql/model'
end
