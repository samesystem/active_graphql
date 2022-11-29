# frozen_string_literal: true

require 'spec_helper'

module ActiveGraphql::Model
  RSpec.describe BuildOrRelation do
    subject(:build_or_relation) { described_class.new(left_query, right_query) }

    let(:model) do
      Class.new do
        include ActiveGraphql::Model

        active_graphql do |c|
          c.url 'http://example.com/graphql'
          c.attributes :shared, :left, :right
        end

        def self.name
          'User'
        end
      end
    end

    let(:shared_query) { model.all.where(shared: true) }
    let(:left_query) { shared_query.where(left: true) }
    let(:right_query) { shared_query.where(right: true) }

    describe '#call' do
      subject(:call) { build_or_relation.call }

      it 'keeps shared query part in non-or part' do
        expect(call.where_attributes.except(:or)).to eq(shared: true)
      end

      it 'moves non shared attributes to "or" part' do
        expect(call.where_attributes[:or]).to eq(left: true, right: true)
      end

      context 'when left and right queries has same field' do
        let(:left_query) { shared_query.where(type: 'left') }
        let(:right_query) { shared_query.where(type: 'right') }

        context 'when shared field has different values' do
          it 'includes both values in "or" query part' do
            expect(call.where_attributes).to eq(
              shared: true,
              or: { type: %w[left right] }
            )
          end
        end
      end

      context 'when left query already has "or" part' do
        let(:left_query) { shared_query.where(left: true).or(shared_query.where(type: 'left')) }

        it 'keeps "or" part and adds additional fields' do
          expect(call.where_attributes).to eq(
            shared: true,
            or: { type: 'left', right: true, left: true }
          )
        end
      end
    end
  end
end
