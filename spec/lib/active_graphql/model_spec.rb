# frozen_string_literal: true

require 'spec_helper'

module ActiveGraphql
  RSpec.describe Model do
    class ParentDummyModel
      include ActiveGraphql::Model

      active_graphql do |c|
        c.resource_name :parent_user
        c.url 'http://example.com/graphql'
      end
    end

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
      subject(:create) { model.create(first_name: first_name) }

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
      subject(:create) { model.create!(first_name: first_name) }

      let(:first_name) { 'Monica' }

      context 'when request is successful' do
        it { is_expected.to be_a(model) }
      end

      context 'when request fails' do
        let(:first_name) { 'invalid' }

        it 'raises error' do
          expect { create }.to raise_error(RecordNotValidError, 'invalid user')
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
          expect { update }.to raise_error(RecordNotValidError, 'invalid user')
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

      let(:record) { model.new(id: 1, first_name: first_name) }
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
  end
end
