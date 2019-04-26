# frozen_string_literal: true

require 'spec_helper'
require 'graphlient'

module ActiveGraphql::Model
  RSpec.describe FindInBatches do
    include_context 'with DummySchema'
    include_context 'with many records'

    subject(:find_in_batches) { described_class.new(relation, batch_size: batch_size) }

    let(:batch_size) { 100 }

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

    let(:relation) { model.all.meta(paginated: true) }

    describe '#call' do
      it 'returns correct number of records' do
        count = 0
        find_in_batches.call { |items| count += items.count }
        expect(count).to eq 101
      end

      context 'when relation has limit' do
        let(:relation) { model.all.meta(paginated: true).limit(25) }
        let(:batch_size) { 7 }

        it 'returns correct number of records' do
          count = 0
          find_in_batches.call { |items| count += items.count }
          expect(count).to eq 25
        end
      end

      context 'when relation has offset' do
        let(:relation) { model.all.meta(paginated: true).offset(93) }
        let(:batch_size) { 4 }

        it 'returns correct number of records' do
          count = 0
          find_in_batches.call { |items| count += items.count }
          expect(count).to eq 8
        end
      end
    end
  end
end
