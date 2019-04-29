require 'spec_helper'

describe_client_api Api::Client::V1::Search do
  describe 'GET /search' do
    let!(:user) { create(:user) }

    before { logged_in(user) }

    it 'should have comments routable path' do
      client_get "search", authentication_token: user.authentication_token, email: user.email
      expect(response.status).not_to eq(404)
    end

    it 'should respond with bad request in case of the missing auth params' do
      client_get "search", authentication_token: user.authentication_token
      expect(response.status).to eq(400)
      client_get "search", email: user.email
      expect(response.status).to eq(400)
    end

    it 'should be successful on request with the valid credentials' do
      client_get "search", authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(200)
    end
  end

end
