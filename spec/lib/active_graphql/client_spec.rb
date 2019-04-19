# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveGraphql::Client do
  subject(:authenticator) { described_class.new({}) }

  describe '.query' do
    subject(:query) { authenticator.query(:findUser) }

    it 'returns action object' do
      expect(query).to be_a(ActiveGraphql::Client::Actions::QueryAction)
    end
  end

  describe '.mutation' do
    subject(:mutation) { authenticator.mutation(:findUser) }

    it 'returns mutation action object' do
      expect(mutation).to be_a(ActiveGraphql::Client::Actions::MutationAction)
    end
  end
end
