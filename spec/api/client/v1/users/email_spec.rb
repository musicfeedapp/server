require 'spec_helper'

describe_client_api Api::Client::V1::Users do
  describe 'POST /users/signup' do
    it 'should be possible to signup using email and password' do
      client_post 'users/signup', email: 'kate@example.com', password: 'password', name: 'Alexandr Korsak'
      expect(response.status).to eq(201)

      user = User.find_by_email('kate@example.com')
      expect(user.present?).to eq(true)
      expect(user.name).to eq('Alexandr Korsak')
    end

    it 'should not allow to create the user with the same email address' do
      User.create!(email: 'kate@example.com', password: 'password')

      client_post 'users/signup', email: 'kate@example.com', password: 'password'
      expect(response.status).to eq(400)
      expect(response.body).to eq("{\"errors\":[{\"id\":\"email\",\"title\":\"Email has already been taken.\"}]}")
    end
  end

  describe 'POST /users/signin' do
    let!(:user) { create(:user, email: 'kate@example.com', password: 'password', password_confirmation: 'password') }

    it 'should be possible to signup using email and password' do
      client_post 'users/signin', email: user.email, password: 'password'
      expect(response.status).to eq(201)
    end

    it 'should not allow to sigin with wrong password' do
      client_post 'users/signin', email: user.email, password: 'new-password'
      expect(response.status).to eq(403)
    end

    it 'should not allow to sigin with wrong password' do
      client_post 'users/signin', email: user.email
      expect(response.status).to eq(400)
    end
  end
end
