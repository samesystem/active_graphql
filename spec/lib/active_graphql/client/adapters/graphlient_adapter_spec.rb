# frozen_string_literal: true

require 'spec_helper'

class ActiveGraphql::Client
  RSpec.describe Adapters::GraphlientAdapter do
    subject(:graphlient_adapter) { described_class.new({}) }

    describe '#post' do
      subject(:post) { graphlient_adapter.post(action) }

      let(:action) { Actions::QueryAction.new(name: :user, client: nil).select(:name) }
      let(:raw_response) { OpenStruct.new(data: OpenStruct.new) }
      let(:raw_client) { graphlient_adapter.send(:graphql_client) }

      before do
        allow(raw_client).to receive(:query).and_return(raw_response)
      end

      it 'makes request' do
        post
        expect(raw_client).to have_received(:query)
      end

      context 'when request is successfull ' do
        it 'returns Response instance' do
          expect(post).to be_a(Response)
        end

        it { is_expected.to be_success }
      end


      context 'when request fails' do
        before do
          allow(raw_client).to receive(:query).and_raise(Graphlient::Errors::GraphQLError, 'boom')
        end

        it 'returns Response instance' do
          expect(post).to be_a(Response)
        end

        it { is_expected.not_to be_success }
      end
    end
  end
end
