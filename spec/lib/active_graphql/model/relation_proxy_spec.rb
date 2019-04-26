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

    describe '#page' do
      subject(:page) { relation_proxy.page(3, per_page: 3) }

      it 'builds correct graphql' do
        expect(page.to_graphql).to eq <<~GRAPHQL
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
  end
  # rubocop:enable RSpec/ExampleLength
end
