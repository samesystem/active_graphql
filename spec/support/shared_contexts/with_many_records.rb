RSpec.shared_context 'with many records' do
  before do
    users = (1..101).map { |id| DummyUser.new(id: id, first_name: "fname#{id}", last_name: 'lname') }
    allow(DummySchema).to receive(:users).and_return(users)
  end
end
