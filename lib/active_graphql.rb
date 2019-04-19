# frozen_string_literal: true

require 'active_graphql/version'

module ActiveGraphql
  class Error < StandardError; end
  class WrongTypeError < ActiveGraphql::Error; end

  autoload :Client, 'active_graphql/client'
  autoload :Model, 'active_graphql/model'
end
