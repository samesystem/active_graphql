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
  module Model # rubocop:disable Metrics/ModuleLength
    require 'active_graphql/model/configuration'
    require 'active_graphql/model/action_formatter'
    require 'active_graphql/model/relation_proxy'
    require 'active_support'
    require 'active_support/core_ext/hash'
    require 'active_model'

    extend ActiveSupport::Concern

    included do # rubocop:disable Metrics/BlockLength
      include ActiveModel::Validations

      validate :validate_graphql_errors

      attr_reader :attributes, :graphql
      attr_writer :graphql_errors, :graphql

      def initialize(attributes)
        @attributes = attributes.deep_transform_keys { |it| it.to_s.underscore.to_sym }
      end

      def mutate(action_name, params = {})
        all_params = { primary_key => primary_key_value }.merge(params)
        response = exec_graphql { |api| api.mutation(action_name.to_s).input(**all_params) }
        self.attributes = response.result.to_h
        self.graphql_errors = response.detailed_errors
        valid?
      end

      def update(params)
        action_name = "update_#{self.class.active_graphql.resource_name}"
        mutate(action_name, params)
      end

      def update!(params)
        success = update(params)
        return true if success

        error_message = (errors['graphql'] || errors.full_messages).first
        raise Errors::RecordNotValidError, error_message
      end

      def attributes=(new_attributes)
        formatted_new_attributes = new_attributes.deep_transform_keys { |it| it.to_s.underscore.to_sym }
        @attributes = attributes.merge(formatted_new_attributes)
      end

      def destroy
        action_name = "destroy_#{self.class.active_graphql.resource_name}"
        response = exec_graphql { |api| api.mutation(action_name).input(primary_key => primary_key_value) }
        response.success?
      end

      def reload
        self.attributes = self.class.find(primary_key_value).attributes
        self
      end

      def save
        if primary_key_value.present?
          update(attributes.except(primary_key))
        else
          self.class.create(attributes)
        end
      end

      def save!
        if primary_key_value.present?
          update!(attributes.reject { |attr, _| attr == primary_key })
        else
          self.class.create!(attributes)
        end
      end

      def read_attribute_for_validation(key)
        key == 'graphql' ? key : super
      end

      protected

      def exec_graphql(*args, &block)
        self.class.exec_graphql(*args, &block)
      end

      def read_graphql_attribute(attribute)
        value = attributes[attribute.name]
        if attribute.decorate_with
          send(attribute.decorate_with, value)
        else
          value
        end
      end

      private

      def graphql_errors
        @graphql_errors ||= []
      end

      def validate_graphql_errors
        graphql_errors.each do |error|
          error_key = error[:field] || 'graphql'
          error_message = error[:short_message] || error[:message]

          errors.add(error_key, error_message)
        end
      end

      def primary_key
        self.class.active_graphql.primary_key
      end

      def primary_key_value
        send(primary_key)
      end
    end

    class_methods do # rubocop:disable Metrics/BlockLength
      delegate :first, :last, :limit, :count, :where, :select, :select_attributes, :find_each, :find, to: :all

      def inherited(sublass)
        super
        sublass.instance_variable_set(:@active_graphql, active_graphql.dup)
      end

      def active_graphql
        @active_graphql ||= ActiveGraphql::Model::Configuration.new
        if block_given?
          yield(@active_graphql)
          @active_graphql.attributes.each do |attribute|
            define_method(attribute.name) do
              read_graphql_attribute(attribute)
            end
          end
        end
        @active_graphql
      end

      def create(params)
        action_name = "create_#{active_graphql.resource_name}"
        response = exec_graphql do |api|
          api.mutation(action_name).input(**params)
        end

        new(response.result.to_h).tap do |record|
          record.graphql_errors = response.detailed_errors if !response.success? || !record.valid?
        end
      end

      def create!(params)
        record = create(params)

        return record if record.valid?

        error_message = (record.errors['graphql'] || record.errors.full_messages).first
        raise Errors::RecordNotValidError, error_message
      end

      def all
        @all ||= ::ActiveGraphql::Model::RelationProxy.new(self)
      end

      def exec_graphql
        formatter = active_graphql.formatter
        api = active_graphql.graphql_client

        raw_action = \
          yield(api)
          .output(*select_attributes)
          .meta(primary_key: active_graphql.primary_key)

        formatter.call(raw_action).response
      end
    end
  end
end
