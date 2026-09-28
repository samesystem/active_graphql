# frozen_string_literal: true

require 'spec_helper'
require 'active_graphql/client/adapters/graphlient_multipart_adapter'

class ActiveGraphql::Client
  RSpec.describe Adapters::GraphlientMultipartAdapter do
    subject(:adapter) { described_class.new(url) }

    let(:url) { 'http://example.com/graphql' }
    let(:document) { GraphQL.parse('mutation { createUser { id } }') }

    describe '#execute' do
      subject(:execute) { adapter.execute(document:, operation_name: nil, variables: {}, context: {}) }

      context 'when server responds with JSON' do
        before do
          stub_request(:post, url).to_return(
            status: 200,
            body: { data: { createUser: { id: 1 } } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
        end

        it 'returns parsed body' do
          expect(execute).to eq('data' => { 'createUser' => { 'id' => 1 } })
        end
      end

      context 'when server responds with 503 HTML page' do
        before do
          stub_request(:post, url).to_return(
            status: 503,
            body: '<html><body><h1>503 Service Unavailable</h1></body></html>',
            headers: { 'Content-Type' => 'text/html' }
          )
        end

        it 'raises FaradayServerError with status code' do
          expect { execute }.to raise_error(Graphlient::Errors::FaradayServerError) do |error|
            expect(error.status_code).to eq 503
          end
        end
      end

      context 'when server responds with 4xx containing GraphQL errors' do
        before do
          stub_request(:post, url).to_return(
            status: 422,
            body: { errors: [{ message: 'invalid' }] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
        end

        it 'returns body so GraphQL errors can be handled' do
          expect(execute).to eq('errors' => [{ 'message' => 'invalid' }])
        end
      end
    end
  end
end
