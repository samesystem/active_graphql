# frozen_string_literal: true

require 'spec_helper'
require 'graphlient'

module ActiveGraphql::Model
  # rubocop:disable RSpec/ExampleLength
  RSpec.describe RelationProxy do
    include_context 'with DummySchema'

    subject(:relation_proxy) { described_class.new(model) }

    let(:model) do
      Class.new do
        include ActiveGraphql::Model

        active_graphql do |c|
          c.url 'http://example.com/graphql'
          c.attributes :id, :first_name
        end

        def self.name
          'User'
        end
      end
    end

    describe '#all' do
      subject(:all) { relation_proxy.all }

      it 'returns itself' do
        expect(all).to be relation_proxy
      end
    end

    describe '#count' do
      subject(:count) { relation_proxy.count }

      it 'returns correct number' do
        expect(count).to eq 3
      end
    end

    describe '#size' do
      subject(:size) { relation_proxy.size }

      it 'returns correct number' do
        expect(size).to eq 3
      end

      context 'when calling multiple times' do
        before do
          allow(DummySchema).to receive(:users).and_call_original
        end

        it 'executes query only once' do
          3.times { size }

          expect(DummySchema).to have_received(:users).once
        end
      end
    end

    describe '#to_a' do
      subject(:to_a) { relation_proxy.to_a }

      it 'returns value from response' do
        expect(to_a.first).to be_a model
      end

      context 'when error happened before' do
        before do
          allow(FindInBatches).to receive(:call).and_raise(StandardError, 'ups')
        end

        it 'raises error again', :aggregate_failures do
          expect { relation_proxy.to_a }.to raise_error('ups')
          expect { relation_proxy.to_a }.to raise_error('ups')
        end
      end

      context 'when there are many records' do
        include_context 'with many records'

        it 'returns all records' do
          expect(to_a.size).to eq 101
        end

        context 'when limit is set' do
          subject(:to_a) { relation_proxy.limit(5).to_a }

          it 'applies limit' do
            expect(to_a.size).to eq 5
          end
        end
      end
    end

    describe '#first' do
      subject(:first) { relation_proxy.first }

      it 'returns correct model' do
        expect(first.id).to eq DummySchema.users.first.id.to_s
      end

      it { is_expected.to be_a(model) }
    end

    describe '#last' do
      subject(:last) { relation_proxy.last }

      it { is_expected.to be_a(model) }

      it 'returns correct model' do
        expect(last.id).to eq DummySchema.users.last.id.to_s
      end
    end

    describe '#where' do
      subject(:where) { relation_proxy.where(something: true) }

      it 'builds correct graphql' do
        expect(where.to_graphql).to eq <<~GRAPHQL
          query {
            users(filter: { something: true }) {
              edges { node { id, firstName } }, pageInfo { hasNextPage }
            }
          }
        GRAPHQL
      end
    end

    describe '#order' do
      subject(:order) { relation_proxy.order(something: :desc) }

      context 'when order direction is given' do
        it 'builds correct graphql' do
          expect(order.to_graphql).to eq <<~GRAPHQL
            query {
              users(order: [{ by: SOMETHING, direction: DESC }]) {
                edges { node { id, firstName } }, pageInfo { hasNextPage }
              }
            }
          GRAPHQL
        end
      end

      context 'when only field name is given' do
        subject(:order) { relation_proxy.order(:something) }

        it 'builds graphql with ASC order direction' do
          expect(order.to_graphql).to eq <<~GRAPHQL
            query {
              users(order: [{ by: SOMETHING, direction: ASC }]) {
                edges { node { id, firstName } }, pageInfo { hasNextPage }
              }
            }
          GRAPHQL
        end
      end

      context 'when multiple fields are given' do
        subject(:order) { relation_proxy.order(:something, something1: :asc, something2: :desc) }

        it 'builds graphql with ASC order direction' do
          expect(order.to_graphql).to eq <<~GRAPHQL
            query {
              users(order: [{ by: SOMETHING, direction: ASC }, { by: SOMETHING1, direction: ASC }, { by: SOMETHING2, direction: DESC }]) {
                edges { node { id, firstName } }, pageInfo { hasNextPage }
              }
            }
          GRAPHQL
        end
      end

      context 'when fields are nil' do
        subject(:order) { relation_proxy.order(nil) }

        it 'builds graphql without order attribute' do
          expect(order.to_graphql).to eq <<~GRAPHQL
            query {
              users {
                edges { node { id, firstName } }, pageInfo { hasNextPage }
              }
            }
          GRAPHQL
        end
      end
    end

    describe '#page' do
      subject(:page) { relation_proxy.page(3) }

      it 'builds correct graphql' do
        expect(page.to_graphql).to eq <<~GRAPHQL
          query {
            users(first: 100, after: "200") {
              edges { node { id, firstName } }, pageInfo { hasNextPage }
            }
          }
        GRAPHQL
      end
    end

    describe '#paginate' do
      subject(:paginate) { relation_proxy.paginate(page: 3, per_page: 3) }

      it 'builds correct graphql' do
        expect(paginate.to_graphql).to eq <<~GRAPHQL
          query {
            users(first: 3, after: "6") {
              edges { node { id, firstName } }, pageInfo { hasNextPage }
            }
          }
        GRAPHQL
      end
    end

    describe '#find' do
      subject(:find) { relation_proxy.find(2) }

      it 'returns correct item' do
        expect(find.id).to eq '2'
      end
    end

    describe '#pluck' do
      subject(:pluck) { relation_proxy.pluck(*pluckable_attributes) }

      let(:pluckable_attributes) { %i[id] }

      context 'with single attribute' do
        it 'returns flat list' do
          expect(pluck).to eq %w[1 2 3]
        end
      end

      context 'with single attribute' do
        let(:pluckable_attributes) { %i[id first_name] }

        it 'returns two dimentional list' do
          expect(pluck).to eq [%w[1 John], %w[2 Ana], %w[3 Bob]]
        end
      end
    end

    describe '#find_each' do
      include_context 'with many records'

      it 'calls block for each record' do
        expect { |block| relation_proxy.find_each(&block) }.to yield_control.exactly(101).times
      end
    end

    describe '#find_in_batches' do
      include_context 'with many records'

      it 'calls block for each batch' do
        expect { |block| relation_proxy.find_in_batches(&block) }.to yield_control.twice
      end
    end

    describe '#blank?' do
      context 'when some records exist' do
        it { is_expected.not_to be_blank }
      end

      context 'when no records exist' do
        before do
          allow(DummySchema).to receive(:users).and_return([])
        end

        it { is_expected.to be_blank }
      end
    end

    describe '#present?' do
      context 'when some records exist' do
        it { is_expected.to be_present }
      end

      context 'when no records exist' do
        before do
          allow(DummySchema).to receive(:users).and_return([])
        end

        it { is_expected.not_to be_present }
      end
    end

    describe '#empty?' do
      context 'when some records exist' do
        it { is_expected.not_to be_empty }
      end

      context 'when no records exist' do
        before do
          allow(DummySchema).to receive(:users).and_return([])
        end

        it { is_expected.to be_empty }
      end
    end

    describe '#or' do
      subject(:relation_proxy_with_or) do
        or_queries.inject(relation_proxy.where(name: 'John')) do |final, query|
          final.or(query)
        end
      end

      let(:or_queries) do
        [
          relation_proxy.where(surname: 'Doe'),
          relation_proxy.where(surname: 'Smith'),
          relation_proxy.where(surname: 'Willson')
        ]
      end

      context 'when or query has same key as "main" query' do
        let(:or_queries) do
          [relation_proxy.where(name: 'Lisa')]
        end

        it 'moves "main" query key to "or" block' do
          expect(relation_proxy_with_or.where_attributes).to eq(
            or: { name: %w[John Lisa] }
          )
        end
      end

      context 'with multiple or queries' do
        it 'joins or queries' do
          expect(relation_proxy_with_or.where_attributes).to eq(
            or: {
              name: 'John',
              surname: %w[Doe Smith Willson]
            }
          )
        end
      end
    end

    describe '#merge' do
      subject(:merge) { left_query.merge(right_query) }

      let(:left_query) { relation_proxy.where(deep: { left: true }) }
      let(:right_query) { relation_proxy.where(deep: { right: true }) }

      it 'merges deep nested where attributes' do
        expect(merge.where_attributes).to eq(deep: { left: true, right: true })
      end
    end

    describe '#method_missing' do
      subject(:method_missing) { relation_proxy.where(name: 'John').public_send(method_name) }

      let(:method_name) { :custom_query }

      let(:model) do
        Class.new do
          include ActiveGraphql::Model

          active_graphql do |c|
            c.url 'http://example.com/graphql'
            c.attributes :name, :custom
          end

          def self.name
            'User'
          end

          def self.custom_query
            where(custom: true)
          end
        end
      end

      context 'when model has defined class method with query' do
        it 'executes class method in query context' do
          expect(method_missing.where_attributes).to eq(name: 'John', custom: true)
        end
      end

      context 'when method does not exist' do
        let(:method_name) { :does_not_exist }

        it 'raises NoMethodError' do
          expect { method_missing }.to raise_error(NoMethodError)
        end
      end
    end
  end
  # rubocop:enable RSpec/ExampleLength
end
