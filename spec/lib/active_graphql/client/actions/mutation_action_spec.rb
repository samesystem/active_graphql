# frozen_string_literal: true

require 'spec_helper'

class ActiveGraphql::Client
  module Actions
    RSpec.describe ActiveGraphql::Client::Actions::MutationAction do
      subject(:mutation) { described_class.new(name: action_name, client: action_client) }

      let(:result) do
        OpenStruct.new(obj: Object.new) do
          def to_h(*)
            { obj: obj }
          end
        end
      end

      let(:action_name) { 'createAccessToken' }
      let(:action_client) { instance_double(Adapters::GraphlientAdapter, post: response) }
      let(:response) { Response.new(result, error) }
      let(:email) { 'test@example.com' }
      let(:error) { nil }

      describe '#to_graphql' do
        subject(:to_graphql) { mutation.select(:shop).to_graphql }

        it 'formats correct graphql code' do # rubocop:disable RSpec/ExampleLength
          expect(to_graphql).to eq <<~GRAPHQL
            mutation {
              createAccessToken {
                shop
              }
            }
          GRAPHQL
        end
      end

      describe '#update' do
        subject(:update) { mutation.select(:token).update(email: email, password: 'password') }

        it 'makes request' do
          update
          expect(action_client).to have_received(:post)
        end
      end

      describe '#update!' do
        subject(:update) { mutation.select(:token).update!(email: email, password: 'password') }

        it 'makes request' do
          update
          expect(action_client).to have_received(:post)
        end

        context 'when response is successfull' do
          it 'returns response result' do
            expect(update).to eq result.obj
          end
        end

        context 'when response is not successfull' do
          let(:result) { nil }
          let(:error) { OpenStruct.new(errors: error_details) }
          let(:error_details) do
            OpenStruct.new(
              details: { 'data' => [{ message: 'Ups!' }] }
            )
          end

          it 'raises error' do
            expect { update }.to raise_error('Ups!')
          end
        end
      end
    end
  end
end
