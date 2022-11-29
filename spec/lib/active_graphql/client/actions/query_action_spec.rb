# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveGraphql::Client::Actions::QueryAction do
  subject(:action) { initial_action }

  let(:initial_action) { described_class.new(name:, client: authenticator_client) }
  let(:name) { :findUser }
  let(:authenticator_client) do
    instance_double(ActiveGraphql::Client::Adapters::GraphlientAdapter, post: response_mock)
  end
  let(:response_mock) { instance_double(ActiveGraphql::Client::Response, result: nil) }

  describe '#response' do
    subject(:action) { initial_action.select(:id, :name).where(type: 'user') }

    it 'makes query' do
      action.response
      expect(authenticator_client).to have_received(:post).with(action)
    end
  end

  describe '#inspect' do
    subject(:inspect) { action.inspect }

    it 'returns pretty info' do
      expect(inspect).to eq(
        '#<ActiveGraphql::Client::Actions::QueryAction ' \
          'name: :findUser, input: {}, output: [], meta: {}' \
          '>'
      )
    end
  end

  describe '#find_by' do
    subject(:action) { initial_action.select(:id, :name) }

    it 'makes query' do
      action.find_by(name: 'john')
      expect(authenticator_client).to have_received(:post).with(kind_of(described_class))
    end
  end

  describe '#select_paginated' do
    subject(:select_paginated) { action.select_paginated(:name) }

    it 'generates graphql for paginated data fetching' do
      expect(select_paginated.to_graphql).to eq <<~GRAPHQL
        query {
          findUser {
            edges { node { name } }
          }
        }
      GRAPHQL
    end
  end

  describe '#where' do
    context 'when "where" is used multiple times' do
      it 'merges where values' do
        where_action = action.where(a: 1).where(b: 2)
        expect(where_action.input_attributes).to eq(a: 1, b: 2)
      end
    end
  end

  describe '#select' do
    context 'when "where" is used multiple times' do
      it 'merges where values' do
        where_action = action.select(:a).select(:b)
        expect(where_action.output_values).to eq(%i[a b])
      end
    end
  end

  describe '#to_grapqhl' do
    context 'when no output field is set' do
      it 'raises exception' do
        expect { action.to_graphql }.to raise_error(ActiveGraphql::Client::Actions::Action::InvalidActionError)
      end
    end

    context 'when output fields are set' do
      subject(:action) { initial_action.select(:id, :name) }

      it 'includes correct action type' do
        expect(action.to_graphql).to include('query')
      end

      it 'includes correct return fields' do
        expect(action.to_graphql).to include('id, name')
      end

      context 'when action has no inputs' do
        it 'generates correct header' do
          expect(action.to_graphql).to include 'findUser {'
        end
      end

      context 'when action has inputs' do
        subject(:action) { initial_action.select(:id).where(id: 123) }

        it 'generates correct action header' do
          expect(action.to_graphql).to include 'findUser(id: 123) {'
        end
      end
    end
  end
end
