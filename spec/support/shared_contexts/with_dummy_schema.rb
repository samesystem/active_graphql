# frozen_string_literal: true

RSpec.shared_context 'with DummySchema' do
  let(:graphql_url) { 'http://example.com/graphql' }

  let(:introspection_request) do
    stub_request(:post, graphql_url)
      .to_return do |request|
        params = JSON.parse(request.body)

        {
          status: 200,
          body: DummySchema.execute(
            params['query'], variables: params['variables']
          ).to_json
        }
      end
  end

  before do
    introspection_request
  end
end
