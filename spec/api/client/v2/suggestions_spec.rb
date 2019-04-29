require 'spec_helper'

describe_client_api Api::Client::V2::Suggestions do
  describe 'GET /suggestions/:identifier/follow' do
    let!(:user) { create(:user) }

    before { logged_in(user) }

    it 'returns json with timelines and followed information' do
      bob = create(:artist)
      v2_client_post "suggestions/#{bob.identifier}/follow", authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(201)
      user.reload

      followings = user.followed.to_a
      expect(followings.size).to eq(1)
      expect(followings[0].id).to eq(bob.id)
    end
  end
end
