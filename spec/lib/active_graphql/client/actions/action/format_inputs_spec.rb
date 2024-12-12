# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveGraphql::Client::Actions::Action::FormatInputs do
  subject(:format_inputs) { described_class.new(inputs, client:) }

  let(:inputs) { {} }
  let(:client) { ActiveGraphql::Client::Adapters::GraphlientAdapter.new(client_config)}
  let(:client_config) { { url: 'http://example.com/graphql' } }

  describe '#call' do
    subject(:call) { format_inputs.call }

    context 'when inputs are empty' do
      it { is_expected.to be_empty }
    end

    context 'when value is symbol' do
      let(:inputs) { { val: :yes } }

      context 'when treat_symbol_as_keyword is false or not set' do
        it 'converts Symbol values to strings' do
          expect(call).to eq 'val: "yes"'
        end
      end

      context 'when treat_symbol_as_keyword is true' do
        let(:client_config) { super().merge(treat_symbol_as_keyword: true) }

        it 'converts Symbol values to keywords' do
          expect(call).to eq 'val: yes'
        end
      end

      context 'when client does not respond to config' do
        let(:client) { nil }

        it 'converts Symbol values to strings' do
          expect(call).to eq 'val: "yes"'
        end
      end

      context 'when client has config as private method' do
        let(:client_class) do
          Class.new(ActiveGraphql::Client::Adapters::GraphlientAdapter) do
            private :config
          end
        end

        let(:client) { client_class.new(client_config) }

        it 'converts Symbol values to strings' do
          expect(call).to eq 'val: "yes"'
        end
      end
    end

    context 'when value is nested hash' do
      let(:inputs) do
        {
          some: {
            deep: {
              value: true
            }
          }
        }
      end

      it 'formats correctly' do
        expect(call).to eq 'some: { deep: { value: true } }'
      end
    end

    context 'when inputs has multiple keys' do
      let(:inputs) do
        {
          some: true,
          other: false
        }
      end

      it 'converts it correctly to graphql structure' do
        expect(call).to eq 'some: true, other: false'
      end
    end

    context 'when value is an Array' do
      let(:inputs) do
        { list: [1, nil, false, '', :foo] }
      end

      it 'converts it correctly to graphql structure' do
        expect(call).to eq 'list: [1, null, false, "", "foo"]'
      end
    end

    context 'when value is deeply nested Array' do
      let(:inputs) do
        { list: { nested: [1, nil, false, '', :foo] } }
      end

      it 'converts it correctly to graphql structure' do
        expect(call).to eq 'list: { nested: [1, null, false, "", "foo"] }'
      end
    end

    context 'when value has unexpected format' do
      let(:inputs) do
        [1]
      end

      it 'raises error' do
        expect { call }.to raise_error(ActiveGraphql::Client::Actions::WrongTypeError)
      end
    end

    context 'when value contains special __keyword_attributes field' do
      context 'when value is symbol' do
        let(:inputs) { { val: :YES, __keyword_attributes: [:val] } }

        it 'converts Symbol values to strings' do
          expect(call).to eq 'val: YES'
        end
      end
    end

    context 'when value is file' do
      context 'when file are deeply nested and wrapped in to array' do
        let(:inputs) do
          {
            val: [
              { file: File.new('/dev/null') },
              { file: File.new('/dev/null') }
            ]
          }
        end

        it 'correctly parses given files input' do
          expect(call).to eq 'val: [{ file: $val_0_file }, { file: $val_1_file }]'
        end
      end
    end
  end
end
