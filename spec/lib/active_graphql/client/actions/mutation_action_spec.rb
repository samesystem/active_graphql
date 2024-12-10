# frozen_string_literal: true

require 'spec_helper'

class ActiveGraphql::Client
  module Actions
    RSpec.describe ActiveGraphql::Client::Actions::MutationAction do
      subject(:mutation) { described_class.new(name: action_name, client: action_client) }

      let(:result) do
        OpenStruct.new(obj: Object.new) do
          def to_h(*)
            { obj: }
          end
        end
      end

      let(:action_name) { 'createAccessToken' }
      let(:action_client) { instance_double(Adapters::GraphlientAdapter, post: response, config: {}) }
      let(:response) { Response.new(result, error) }
      let(:email) { 'test@example.com' }
      let(:error) { nil }

      describe '#graphql_variables' do
        subject(:graphql_variables) { mutation.select(:shop).graphql_variables }

        context 'when inputs does not contain files' do
          it { is_expected.to be_empty }
        end

        context 'when input attributes includes file' do
          subject(:graphql_variables) do
            mutation.where(file: File.new('/dev/null')).select(:shop)
                    .graphql_variables
          end

          it 'contains file' do
            expect(graphql_variables[:file]).to be_a(File)
          end
        end

        context 'when input attributes includes files list' do
          subject(:graphql_variables) do
            mutation.where(files: [File.new('/dev/null')]).select(:shop)
                    .graphql_variables
          end

          it 'contains files' do
            expect(graphql_variables[:files].first).to be_a(File)
          end
        end

        context 'when input attributes deeply nested file' do
          subject(:graphql_variables) do
            mutation.where(input: { deep: { some_file: File.new('/dev/null') } })
                    .select(:shop)
                    .graphql_variables
          end

          it 'contains files with full path name' do
            expect(graphql_variables[:input_deep_some_file]).to be_a(File)
          end
        end

        context 'when input attributes includes files list with nesting' do
          subject(:graphql_variables) do
            mutation.where(input: [{ some_file: File.new('/dev/null') }])
                    .select(:shop)
                    .graphql_variables
          end

          it 'contains files with full path name' do
            expect(graphql_variables[:input_0_some_file]).to be_a(File)
          end
        end
      end

      describe '#to_graphql' do
        subject(:to_graphql) { mutation.select(:shop).to_graphql }

        context 'when inputs does not contain files' do
          it 'formats correct graphql code' do
            expect(to_graphql).to eq <<~GRAPHQL
              mutation {
                createAccessToken {
                  shop
                }
              }
            GRAPHQL
          end
        end

        context 'when input attributes includes file' do
          subject(:to_graphql) { mutation.where(file: File.new('/dev/null')).select(:shop).to_graphql }

          it 'formats correct graphql code' do
            expect(to_graphql).to eq <<~GRAPHQL
              mutation($file: File!) {
                createAccessToken(file: $file) {
                  shop
                }
              }
            GRAPHQL
          end
        end

        context 'when input attributes includes nested file' do
          subject(:to_graphql) do
            mutation.where(input: { file: File.new('/dev/null') })
                    .select(:shop)
                    .to_graphql
          end

          it 'formats correct graphql code' do
            expect(to_graphql).to eq <<~GRAPHQL
              mutation($input_file: File!) {
                createAccessToken(input: { file: $input_file }) {
                  shop
                }
              }
            GRAPHQL
          end
        end

        context 'when input attributes includes files list' do
          subject(:to_graphql) { mutation.where(files: [File.new('/dev/null')]).select(:shop).to_graphql }

          it 'formats correct graphql code' do
            expect(to_graphql).to eq <<~GRAPHQL
              mutation($files: [File!]!) {
                createAccessToken(files: $files) {
                  shop
                }
              }
            GRAPHQL
          end
        end
      end

      describe '#update' do
        subject(:update) { mutation.select(:token).update(email:, password: 'password') }

        it 'makes request' do
          update
          expect(action_client).to have_received(:post)
        end
      end

      describe '#update!' do
        subject(:update) { mutation.select(:token).update!(email:, password: 'password') }

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
