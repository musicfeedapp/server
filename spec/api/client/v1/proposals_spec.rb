require 'spec_helper'

describe_client_api Api::Client::V1::Proposals do
  include UserMocks

  let!(:user) { create(:user) }

  describe 'PUT /proposals' do
    let(:user) { create(:user) }
    let(:kate) { create(:user, facebook_id: '1') }
    let(:fred) { create(:user, facebook_id: '3') }

    before do
      user.follow!(kate)
      user.follow!(fred)
    end

    it 'should add a following to the user by facebook ids' do
      expect(user.followed.to_a.size).to eq(2)

      client_put 'proposals', facebook_id: [{ facebook_id: '1', followed: true }, { facebook_id: '3', followed: false }], authentication_token: user.authentication_token, email: user.email
      user.reload

      expect(response.status).to eq(200)

      expect(user.followed.to_a.size).to eq(1)
      expect(user.followed[0].id).to eq(kate.id)
    end
  end

end
