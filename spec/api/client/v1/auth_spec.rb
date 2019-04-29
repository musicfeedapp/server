require 'spec_helper'

describe Api::Client::V1::Auth, api: true do

  subject { Class.new(Grape::API) }

  before do
    subject.class_eval do
      helpers Api::Client::V1::Auth
    end
    subject.before   { authenticate_user! }
    subject.get('/') { current_user.email }
  end

  def app
    subject
  end

  describe '.current_user' do
    let!(:user) { double('User', email: 'kate@example.com', authentication_token: 'auth-token') }

    before do
      allow(User).to receive(:find_by_email).with_args('kate@example.com').and_return(user)
      allow(User).to receive(:find_by_email).with_args('fred@example.com')
    end

    it 'should find current user based on the email and tokens' do
      get '/', email: 'kate@example.com', authentication_token: 'auth-token'
      expect(response.status).to eq(200)
      expect(response.body).to eq('kate@example.com')
    end

    it 'should raise 403 in case of invalid email' do
      get '/', email: 'fred@example.com', authentication_token: 'auth-token'
      expect(response.status).to eq(403)
    end

    it 'should raise 403 in case of invalid authentication token' do
      get '/', email: 'kate@example.com', authentication_token: 'invalid-token'
      expect(response.status).to eq(403)
    end
  end

end

