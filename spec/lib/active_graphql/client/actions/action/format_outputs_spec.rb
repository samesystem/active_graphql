# frozen_string_literal: true

require 'spec_helper'

class ActiveGraphql::Client::Actions::Action
  RSpec.describe FormatOutputs do
    subject(:format_outputs) { described_class.new(outputs) }

    let(:outputs) do
      [:field, { other: :other_field, nested_field: { deep: :uhum } }]
    end

    describe '#call' do
      subject(:call) { format_outputs.call }

      context 'when outputs are empty' do
        let(:outputs) { [] }

        it { is_expected.to be_empty }
      end

      context 'with multiple fields' do
        let(:outputs) { %i[field_one field_two] }

        it 'formats correctly' do
          expect(call).to eq 'field_one, field_two'
        end
      end

      context 'with hash field' do
        let(:outputs) { [{ field_one: :one, field_two: :two }] }

        it 'formats correctly' do
          expect(call).to eq 'field_one { one }, field_two { two }'
        end
      end

      context 'with multiple hash fields' do
        let(:outputs) { [{ field_one: :one }, { field_two: :two }] }

        it 'formats correctly' do
          expect(call).to eq 'field_one { one }, field_two { two }'
        end
      end

      context 'when fields are not formatted properly' do
        let(:outputs) { [{ field: 1 }] }

        it 'raises error' do
          expect { call }.to raise_error(ActiveGraphql::Client::Actions::WrongTypeError)
        end
      end

      context 'when value is nested hash' do
        let(:outputs) do
          [
            {
              some: {
                deep: {
                  value: %i[yes no maybe]
                }
              }
            }
          ]
        end

        it 'formats correctly' do
          expect(call).to eq 'some { deep { value { yes, no, maybe } } }'
        end
      end
    end
  end
end
