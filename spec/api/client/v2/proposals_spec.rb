require 'spec_helper'

describe_client_api Api::Client::V2::Proposals do
  include UserMocks

  let!(:user) { create(:user) }

  describe 'PUT /proposals' do
    let(:user) { create(:user) }
    let(:kate) { create(:user, ext_id: '1') }
    let(:fred) { create(:user, ext_id: '3') }

    before do
      user.follow!(kate)
      user.follow!(fred)
    end

    it 'should add a following to the user by facebook ids' do
      client_put 'proposals', ext_ids: [{ ext_id: '1', followed: true }, { ext_id: '3', followed: false }], authentication_token: user.authentication_token, email: user.email
      user.reload

      expect(user.followed.to_a.size).to eq(2)
      expect(user.followed[0].id).to eq(kate.id)
    end
  end

end
