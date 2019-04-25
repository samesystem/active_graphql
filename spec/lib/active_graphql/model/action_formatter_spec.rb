# frozen_string_literal: true

require 'spec_helper'

module ActiveGraphql
  RSpec.describe Model::ActionFormatter do
    subject(:action_formatter) { described_class.new(raw_action) }

    let(:initial_raw_action) { Client::Actions::QueryAction.new(name: 'find_user', client: nil) }
    let(:raw_action) { initial_raw_action }

    describe '#call' do
      subject(:call) { action_formatter.call }

      it { is_expected.to be_a(raw_action.class) }

      context 'with nested output' do
        let(:raw_action) { initial_raw_action.select(some_deep: { some_nested: :some_value }) }

        it 'generates new action with correct output' do
          expect(call.output_values).to eq([{ 'someDeep' => { 'someNested' => 'someValue' } }])
        end
      end
    end
  end
end
