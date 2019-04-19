# frozen_string_literal: true

module ActiveGraphql
  # Allows to have ActiveRecord-like models which comunicates with graphql endpoint instead of DB:
  # class RemoteUser
  #   include ActiveGraphql::Model
  #
  #   graphql_url('http://localhost:3001/graphql')
  #   graphql_attributes :id, :full_name
  # end
  #
  # Now you can do:
  # RemoteUser.where(created_at { from: '2000-01-01', to: '2010-01-01' })
  # RemoteUser.all.for_each { |user| ... }
  # RemoteUser.where(...).count
  #
  # Model expects that graphql has GraphqlRails CRUD actions with default naming (createRemoteUser, remoteUsers, etc.)
  module Model
    extend ActiveSupport::Concern

    included do
      attr_reader :attributes

      def initialize(attributes)
        @attributes = attributes.deep_transform_keys { |it| it.to_s.underscore.to_sym }
      end

      private

      def read_graphql_attribute(attribute_name)
        attributes[attribute_name.to_sym]
      end
    end

    class_methods do # rubocop:disable Metrics/BlockLength
      delegate :first, :last, :count, :where, to: :all

      def inherited(sublass)
        sublass.instance_variable_set(:@graphql_url, controller_configuration.graphql_url)
      end

      def graphql_url(url = nil)
        @graphql_url = url if url
        @graphql_url
      end

      def graphql_client
        @graphql_client ||= ActiveGraphql::Client.new(url: graphql_url)
      end

      def graphql_attributes(*attributes, **complex_attributes)
        return @graphql_attributes if attributes.empty?

        @graphql_attributes = attributes + complex_attributes.map { |k, v| { k => v } }

        (attributes + complex_attributes.keys).each do |attribute|
          define_method(attribute) do
            read_graphql_attribute(attribute)
          end
        end
      end

      def graphql_resource_name(resource_name = nil)
        @graphql_resource_name = resource_name if resource_name
        @graphql_resource_name ||= name.demodulize.camelize(:lower)
      end

      def belongs_to(association)
        @belongs_to ||= Set.new
        @belongs_to += association.to_sym
      end

      def all
        @all ||= ::ActiveGraphql::RelationProxy.new(self)
      end
    end
  end
end
