require 'spec_helper'

describe_client_api Api::Client::V2::Profile do
  describe 'PUT /profile' do
    let!(:user) { create(:user) }

    before { user.authentications.destroy_all }

    it 'should be possible to update / delete auth token for facebook' do
      expect(user.reload.authentications.size).to eq(0)

      v2_client_put '/profile', email: user.email, authentication_token: user.authentication_token, facebook: { auth_token: 'something', uid: 'uid' }
      expect(response.status).to eq(200)

      expect(user.reload.authentications.size).to eq(1)
      expect(user.authentications[0].provider).to eq('facebook')
      expect(user.authentications[0].auth_token).to eq('something')
      expect(user.authentications[0].uid).to eq('uid')

      v2_client_put '/profile', email: user.email, authentication_token: user.authentication_token, facebook: { destroy: 1 }
      expect(response.status).to eq(200)

      expect(user.reload.authentications.size).to eq(0)
    end
  end
end
