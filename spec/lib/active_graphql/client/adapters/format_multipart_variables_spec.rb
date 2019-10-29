# frozen_string_literal: true

require 'spec_helper'
require 'active_graphql/client/adapters/format_multipart_variables'

module ActiveGraphql::Client::Adapters
  RSpec.describe FormatMultipartVariables do
    subject(:format_multipart_variables) { described_class.new(variables) }

    describe '#call' do
      subject(:call) { format_multipart_variables.call }

      context 'when file does not have mime type' do
        let(:variables) do
          {
            val: { file: File.new('/dev/null') }
          }
        end

        it 'raises an error' do
          expect { call }.to raise_error(NoMimeTypeException)
        end
      end

      context 'when variable is not a file' do
        let(:variables) do
          {
            val: { name: 'John Doe' }
          }
        end

        it 'returns correct value' do
          expect(call).to eq(variables)
        end
      end

      context 'when file is deeply nested' do
        let(:variables) do
          {
            val: { file: File.new('spec/fixtures/test.txt') }
          }
        end

        it 'contverts file to Faraday::UploadIO' do
          expect(call[:val][:file]).to be_a(Faraday::UploadIO)
        end
      end

      context 'when files are in array' do
        let(:variables) do
          {
            val: [File.new('spec/fixtures/test.txt'), File.new('spec/fixtures/test.txt')]
          }
        end

        it 'contverts file to Faraday::UploadIO' do
          expect(call[:val]).to all be_a(Faraday::UploadIO)
        end
      end

      context 'when file is in array and then nested' do
        let(:variables) do
          {
            val: [
              { file: File.new('spec/fixtures/test.txt') },
              { file: File.new('spec/fixtures/test.txt') }
            ]
          }
        end

        it 'contverts file to Faraday::UploadIO' do
          result = call[:val].map { |val| val[:file] }
          expect(result).to all be_a(Faraday::UploadIO)
        end
      end
    end
  end
end
