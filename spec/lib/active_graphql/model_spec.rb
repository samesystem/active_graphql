# frozen_string_literal: true

require 'spec_helper'
require 'graphlient/errors'

class ParentDummyModel
  include ActiveGraphql::Model

  active_graphql do |c|
    c.resource_name :parent_user
    c.url 'http://example.com/graphql'
  end
end

module ActiveGraphql
  RSpec.describe Model do
    subject(:model) do
      Class.new(ParentDummyModel) do
        def self.name
          'User'
        end

        active_graphql do |c|
          c.resource_name :user
          c.attributes :id, :first_name
        end

        attr_writer :first_name
      end
    end

    include_context 'with DummySchema'

    describe '.all' do
      subject(:all) { model.all }

      it { is_expected.to be_a(Model::RelationProxy) }
    end

    describe '.active_graphql' do
      subject(:active_graphql) { model.active_graphql }

      it 'inherits config from parent' do
        expect(active_graphql.resource_name).to eq :user
      end

      it 'does not affect parent class config' do
        expect(ParentDummyModel.active_graphql.resource_name).to eq :parent_user
      end
    end

    describe '#create' do
      subject(:create) { model.create(first_name:) }

      let(:first_name) { 'Monica' }

      context 'when request is successful' do
        it { is_expected.to be_a(model) }
        it { is_expected.to be_valid }
      end

      context 'when request fails' do
        let(:first_name) { 'invalid' }

        it { is_expected.to be_a(model) }
        it { is_expected.not_to be_valid }
      end
    end

    describe '#create!' do
      subject(:create) { model.create!(first_name:) }

      let(:first_name) { 'Monica' }

      context 'when request is successful' do
        it { is_expected.to be_a(model) }
      end

      context 'when request fails' do
        let(:first_name) { 'invalid' }

        it 'raises error' do
          expect { create }.to raise_error(Errors::RecordNotValidError, 'invalid user')
        end
      end
    end

    describe '#mutate' do
      subject(:mutate) { record.mutate(action_name, params) }

      let(:action_name) { :force_user_update }
      let(:params) { { first_name: new_attribute_value } }
      let(:record) { model.new(id: 1) }

      context 'when request is successful' do
        let(:new_attribute_value) { 'valid' }

        it 'returns true' do
          expect(mutate).to eq(true)
        end

        it 'keeps record valid' do
          expect { mutate }.not_to change(record, :valid?).from(true)
        end

        context 'without params' do
          subject(:mutate) { record.mutate(action_name) }

          it 'returns true' do
            expect(mutate).to eq(true)
          end
        end
      end

      context 'when request fails' do
        let(:new_attribute_value) { 'invalid' }
        let(:params) { { first_name: new_attribute_value } }

        it { is_expected.to be false }

        it 'sets record invalid' do
          expect { mutate }.to change(record, :valid?).from(true).to(false)
        end
      end
    end

    describe '#update' do
      subject(:update) { record.update(first_name: new_attribute_value) }

      let(:record) { model.new(id: 1) }
      let(:new_attribute_value) { 'Lisa' }

      context 'when request is successful' do
        it 'changes attibutes' do
          expect { update }.to change(record, :first_name).to(new_attribute_value)
        end

        it { is_expected.to be true }

        it 'keeps record valid' do
          expect { update }.not_to change(record, :valid?).from(true)
        end
      end

      context 'when request fails' do
        let(:new_attribute_value) { 'invalid' }

        it { is_expected.to be false }

        it 'sets record invalid' do
          expect { update }.to change(record, :valid?).from(true).to(false)
        end
      end
    end

    describe '#update!' do
      subject(:update) { record.update!(first_name: new_attribute_value) }

      let(:record) { model.new(id: 1) }
      let(:new_attribute_value) { 'Lisa' }

      context 'when request is successful' do
        it 'changes attibutes' do
          expect { update }.to change(record, :first_name).to(new_attribute_value)
        end

        it { is_expected.to be true }

        it 'keeps record valid' do
          expect { update }.not_to change(record, :valid?).from(true)
        end
      end

      context 'when request fails' do
        let(:new_attribute_value) { 'invalid' }

        it 'raises error' do
          expect { update }.to raise_error(Errors::RecordNotValidError, 'invalid user')
        end
      end
    end

    describe '#destroy' do
      subject(:destroy) { record.destroy }

      let(:record) { model.new(id: 1) }

      context 'when request is successful' do
        it { is_expected.to be true }
      end

      context 'when request fails' do
        let(:record) { model.new(id: -10) }

        it { is_expected.to be false }
      end
    end

    describe '#reload' do
      subject(:reload) { record.reload }

      let(:record) { model.new(id: 1, first_name:) }
      let(:first_name) { 'John' }

      context 'when request is successful' do
        let(:new_first_name) { 'Elon' }

        before do
          allow(record.class).to receive(:find).with(record.id).and_call_original
          record.attributes.merge!(first_name: new_first_name)
        end

        it 'fetches same instance' do
          expect(reload.id).to eq(record.id)
        end

        it 'makes find query' do
          reload
          expect(record.class).to have_received(:find)
        end

        it 'resets values' do
          expect { reload }.to change(record, :first_name).from(new_first_name).to(first_name)
        end
      end
    end

    describe '#read_graphql_attribute' do
      it 'returns attribute from response' do
        expect(model.find(1).first_name).to eq 'John'
      end

      context 'when attribute has decorator' do
        subject(:model) do
          Class.new(ParentDummyModel) do
            def self.name
              'User'
            end

            active_graphql do |c|
              c.resource_name :user
              c.attribute :first_name, decorate_with: :upcase
            end

            def upcase(name)
              name.upcase
            end
          end
        end

        it 'decorates attribute from response' do
          expect(model.find(1).first_name).to eq 'JOHN'
        end
      end
    end

    describe '#errors' do
      subject(:errors) { record.errors }

      let(:record) { model.find(1) }

      describe 'response errors handling' do
        let(:graphql_object) { nil }
        let(:error_field) { 'graphql' }
        let(:error_message) { 'Oh snap' }
        let(:error_details) { { 'data' => [error_data] } }
        let(:response) { ActiveGraphql::Client::Response.new(graphql_object, graphql_error) }
        let(:graphql_error) do
          instance_double(
            Graphlient::Errors::GraphQLError,
            errors: OpenStruct.new(details: error_details)
          )
        end

        before do
          allow(record).to receive(:exec_graphql).and_return(response)
          record.update(first_name: 'Tom')
        end

        shared_examples 'contains graphql error' do
          it 'contains graphql errors', :aggregate_failures do
            expect(errors).to be_a(ActiveModel::Errors)
            expect(errors[error_field]).to eq([error_message])
            expect(errors.messages[error_field.to_sym]).to eq([error_message])
            expect(errors.details[error_field.to_sym]).to eq([{ error: error_message }])
          end
        end

        context 'when grahql error does not contain specified field' do
          let(:error_data) { { 'message' => error_message } }

          include_examples 'contains graphql error'
        end

        context 'when grahql error contains specified field' do
          let(:error_field) { 'first_name' }

          let(:error_data) do
            {
              'message' => error_message,
              'field' => error_field
            }
          end

          include_examples 'contains graphql error'
        end

        context 'when grahql error contains short message field' do
          let(:short_error_message) { 'short_error_message' }
          let(:error_message) { short_error_message }
          let(:error_data) do
            {
              'message' => 'Long message',
              'short_message' => short_error_message
            }
          end

          include_examples 'contains graphql error'
        end
      end

      describe '#add' do
        before do
          record.errors.add(error_attribute, error_message)
        end

        shared_examples 'can handle stringy errors' do
          it 'contains defined error' do
            expect(record.errors[error_attribute]).to include(error_message)
          end
        end

        shared_examples 'can handle symbolic errors' do
          it 'contains builds activemodel error', :aggregate_failures do
            expect(record.errors[error_attribute].first).to include('activemodel.errors')
            expect(record.errors[error_attribute].first).to include(error_message.to_s)
          end
        end

        context 'when error is from graphql' do
          let(:error_attribute) { 'graphql' }

          context 'when error message is string value' do
            let(:error_message) { 'stringy error message' }

            include_examples 'can handle stringy errors'
          end

          context 'when error message is symbol' do
            let(:error_message) { :symbolic_error }

            include_examples 'can handle symbolic errors'
          end
        end

        context 'when error is from another attribute' do
          let(:error_attribute) { 'first_name' }

          context 'when error message is string value' do
            let(:error_message) { 'stringy error message' }

            include_examples 'can handle stringy errors'
          end

          context 'when error message is symbol' do
            let(:error_message) { :symbolic_error }

            include_examples 'can handle symbolic errors'
          end
        end
      end
    end

    describe '#save' do
      subject(:save) { record.save }

      let(:record) { model.new(params) }

      context 'when model attributes contains primary key attribute' do
        let(:params) { { id: 1, first_name: 'John Pelek' } }

        before do
          allow(record).to receive(:update)
        end

        it 'performs update mutation' do
          save
          expect(record).to have_received(:update).with(first_name: 'John Pelek')
        end
      end

      context 'when model attributes does not include primary key attribute' do
        let(:params) { { first_name: 'John Pelek' } }

        before do
          allow(record.class).to receive(:create)
        end

        it 'performs create mutation' do
          save
          expect(record.class).to have_received(:create).with(params)
        end
      end
    end

    describe '#save!' do
      subject(:save!) { record.save! }

      let(:record) { model.new(params) }

      context 'when model attributes contains primary key attribute' do
        let(:params) { { id: 1, first_name: 'John Pelek' } }

        before do
          allow(record).to receive(:update!)
        end

        it 'performs update mutation' do
          save!
          expect(record).to have_received(:update!).with(first_name: 'John Pelek')
        end
      end

      context 'when model attributes does not include primary key attribute' do
        let(:params) { { first_name: 'John Pelek' } }

        before do
          allow(record.class).to receive(:create!)
        end

        it 'performs create mutation' do
          save!
          expect(record.class).to have_received(:create!).with(params)
        end
      end
    end
  end
end
