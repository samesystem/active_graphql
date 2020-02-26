# frozen_string_literal: true

require 'spec_helper'
require 'graphql/client/schema/object_type'
require 'graphlient/errors'

RSpec.describe ActiveGraphql::Client::Response do
  subject(:response) { described_class.new(graphql_object, error) }

  let(:error) { nil }
  let(:data) { { 'graphqlQuery' => response_data } }
  let(:response_data) do
    {
      'modelData' => {
        'field1' => 'a',
        'field2' => 'b'
      }
    }
  end
  let(:error_message) { { 'message' => 'Oh snap' } }
  let(:error_details) { { 'data' => [error_message] } }
  let(:graphql_error) do
    instance_double(
      Graphlient::Errors::GraphQLError,
      errors: OpenStruct.new(details: error_details)
    )
  end

  let(:graphql_object) do
    # rubocop:disable RSpec/VerifiedDoubles
    double(
      'GraphQL::Client::Schema::ObjectClass',
      to_h: data,
      graphql_query: OpenStruct.new(response_data)
    )
    # rubocop:enable RSpec/VerifiedDoubles
  end

  describe '#detailed_errors' do
    subject(:detailed_errors) { response.detailed_errors }

    context 'when request is successful' do
      let(:error) { nil }

      it { is_expected.to be_blank }
    end

    context 'when request is not successful' do
      let(:error) { graphql_error }

      it { is_expected.to eq([error_message]) }
    end
  end

  describe '#errors' do
    subject(:errors) { response.errors }

    context 'when request is successful' do
      let(:error) { nil }

      it { is_expected.to be_blank }
    end

    context 'when request is not successful' do
      let(:error) { graphql_error }

      it { is_expected.to eq([error_message['message']]) }
    end
  end
end
