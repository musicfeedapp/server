require 'spec_helper'

require 'rspec/expectations'
require 'rspec/mocks'

describe_client_api Api::Client::V1::Users do
  include UserMocks

  describe 'POST /users/facebook' do

    let(:user_attributes) { { email: 'kate@example.com', authentication_token: 'auth-token', first_name: "Kate", last_name: "Watson" } }
    let!(:user) { create(:user, user_attributes.merge(authentications: [build(:facebook_authentication)])) }

    before do
      allow_any_instance_of(Facebook::Proposals::Maker).to receive(:create)
    end

    before do
      allow(User).to receive(:find_or_create_by_facebook_auth_token).with_args('wrong')
      allow(User).to receive(:find_or_create_by_facebook_auth_token).with_args('token').and_return(user)
    end

    it 'should have facebook routable path' do
      client_post 'users/facebook', auth_token: 'token'
      expect(response.status).not_to eq(404)
    end

    it 'should authenticate a user using facebook oauth details' do
      client_post 'users/facebook', auth_token: 'token', email: user.email
      expect(response.status).to eq(201)

      new_user_attributes = JSON.parse(response.body)
      expect(new_user_attributes['email']).to eq(user_attributes[:email])
    end

    it 'should not authenticate a user in case of impossible login via facebook oauth' do
      client_post 'users/facebook', auth_token: 'wrong'
      expect(response.status).to eq(403)
    end

    describe 'GET /users/friends' do
      let(:user_attributes) { { email: 'kate@example.com', authentication_token: 'auth-token', first_name: "Kate", last_name: "Watson" } }
      let!(:user) { create(:user, user_attributes.merge(authentications: [build(:facebook_authentication)])) }

      it 'when required params are present ' do
        client_post 'users/friends', authentication_token: user.authentication_token, email: user.email, id: user.id
        expect(response.status).not_to eq(404)
      end

      it 'when required params are not present' do
        client_post 'users/friends'
        expect(response.status).to eq(405)
      end

      it 'when required params are present' do
        user1 = create(:user, name: "facebook1")
        user.friend!(user1)
        client_get 'users/friends', authentication_token: user.authentication_token, email: user.email, id: user.id, username: "testing123"

        json_response do |json|
          expect(json).to have(1).item
          expect(json.first["id"]).to eq(user1.id)
        end
      end
    end
  end

  describe 'PUT /users/update' do
    let(:user_attributes) { { email: 'kate@example.com', authentication_token: 'auth-token', first_name: "Kate", last_name: "Watson" } }
    let!(:user) { create(:user, user_attributes.merge(authentications: [build(:facebook_authentication)])) }

    it 'when required params are present ' do
      client_post 'users/update', authentication_token: user.authentication_token, email: user.email, id: user.id
      expect(response.status).not_to eq(404)
    end

    it 'when required params are not present' do
      client_post 'users/update'
      expect(response.status).to eq(405)
    end

    it 'when required params are not present' do
      client_post 'users/update', authentication_token: user.authentication_token, email: user.email, id: user.id, username: "testing123"
      user.update(username: "testing123")
      expect(user.reload.username).to eq("testing123")
      expect(user.username).not_to eq("Zoro4")
    end
  end
end

