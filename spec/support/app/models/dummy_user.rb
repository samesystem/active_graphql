# frozen_string_literal: true

class DummyUser
  require 'graphql_rails'
  include GraphqlRails::Model

  graphql do |c|
    c.name 'User'
    c.attribute :id
    c.attribute :first_name
    c.attribute :last_name
    c.attribute :full_name
  end

  graphql.input do |c|
    c.attribute :first_name
    c.attribute :last_name
  end

  graphql.input(:filter) do |c|
    c.attribute :ids, type: '[ID!]'
    c.attribute :first_names, type: '[ID!]'
  end

  attr_accessor :first_name, :last_name, :id

  def initialize(params)
    params.each { |field, val| public_send("#{field}=", val) }
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
