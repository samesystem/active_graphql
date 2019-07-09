# frozen_string_literal: true

require 'graphql'
require 'graphql_rails'
require 'active_record'
require_relative 'models/dummy_user'

class DummySchema < GraphQL::Schema
  module PlainCursorEncoder
    def self.encode(plain, _nonce)
      plain
    end

    def self.decode(plain, _nonce)
      plain
    end
  end

  def self.users
    [%w[John Doe], %w[Ana Smith], %w[Bob Willson]].map.with_index do |(first_name, last_name), i|
      DummyUser.new(id: i + 1, first_name: first_name, last_name: last_name)
    end
  end

  class QueryType < GraphQL::Schema::Object
    field :user, DummyUser.graphql.graphql_type, null: false, method: :user do
      description 'Find invoice'
      argument :id, Integer, required: true
    end

    field :createUser, DummyUser.graphql.graphql_type, null: false, method: :create_user do
      description 'Find invoice'
      argument :id, Integer, required: true
    end

    field :updateUser, DummyUser.graphql.graphql_type, null: false, method: :update_user do
      description 'Find invoice'
      argument :id, Integer, required: true
    end

    field :destroyUser, DummyUser.graphql.graphql_type, null: false, method: :destroy_user do
      description 'Find invoice'
      argument :id, Integer, required: true
    end

    field :users, DummyUser.graphql.connection_type, null: true do
      description 'Find invoice'
      argument :filter, DummyUser.graphql.input(:filter).graphql_input_type, required: false
    end

    def user(id:)
      DummySchema.users.detect { |user| user.id == id }
    end

    def users(*)
      DummySchema.users
    end
  end

  class MytationType < GraphQL::Schema::Object
    field :createUser, DummyUser.graphql.graphql_type, null: false, method: :create_user do
      description 'Find invoice'
      argument :input, DummyUser.graphql.input.graphql_input_type, required: true
    end

    field :updateUser, DummyUser.graphql.graphql_type, null: false, method: :update_user do
      description 'Find invoice'
      argument :id, Integer, required: true
      argument :input, DummyUser.graphql.input.graphql_input_type, required: true
    end

    field :destroyUser, DummyUser.graphql.graphql_type, null: false, method: :destroy_user do
      description 'Find invoice'
      argument :id, Integer, required: true
    end

    def update_user(id:, input:)
      raise(GraphQL::ExecutionError, 'invalid user') if input[:first_name] == 'invalid'

      DummyUser.new(input.to_h.merge(id: id))
    end

    def destroy_user(id:)
      DummySchema.users.detect { |user| user.id == id }.tap do |user|
        raise(GraphQL::ExecutionError, 'user does not exist') unless user
      end
    end

    def create_user(input:)
      raise(GraphQL::ExecutionError, 'invalid user') if input[:first_name] == 'invalid'

      DummyUser.new(id: rand(1_000..999_999), **input.to_h)
    end
  end

  cursor_encoder(PlainCursorEncoder)
  query(QueryType)
  mutation(MytationType)
end
