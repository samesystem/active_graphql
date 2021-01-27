# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveGraphql::Client::Actions::Action::FormatVariableInputs do
  subject(:format_inputs) { described_class.new(inputs) }

  let(:inputs) { {} }

  describe '#call' do
    subject(:call) { format_inputs.call }

    context 'when inputs are empty' do
      it { is_expected.to be_empty }
    end

    context 'when value is file' do
      let(:inputs) { { val: File.new('/dev/null') } }

      context 'when file is not nested' do
        it 'sets required File type' do
          expect(call).to eq '$val: File!'
        end
      end

      context 'when file is deeply nested' do
        let(:inputs) { { val: { deep: File.new('/dev/null') } } }

        it 'sets required File type' do
          expect(call).to eq '$val_deep: File!'
        end
      end

      context 'when file is deeply nested and wrapped in to array' do
        let(:inputs) do
          {
            val: [
              { file: File.new('/dev/null') },
              { file: File.new('/dev/null') }
            ]
          }
        end

        it 'sets required File type' do
          expect(call).to eq '$val_0_file: File!, $val_1_file: File!'
        end
      end
    end

    context 'when value is not file' do
      let(:inputs) { { val: 'I am not file!' } }

      it { is_expected.to be_empty }
    end
  end
end
