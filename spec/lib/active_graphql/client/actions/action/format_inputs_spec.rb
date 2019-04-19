# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveGraphql::Client::Actions::Action::FormatInputs do
  subject(:format_inputs) { described_class.new(inputs) }

  let(:inputs) { {} }

  describe '#call' do
    subject(:call) { format_inputs.call }

    context 'when inputs are empty' do
      it { is_expected.to be_empty }
    end

    context 'when value is symbol' do
      let(:inputs) { { val: :yes } }

      it 'convers Symbol values to strings' do
        expect(call).to eq 'val: "yes"'
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
  end
end
