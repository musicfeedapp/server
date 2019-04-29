require 'spec_helper'

describe_client_api Api::Client::V5::ContactList do
  let!(:user) { create(:user) }
  before { logged_in(user) }

  describe 'POST /contacts' do
    let!(:contact_list) { [{ 'email' => 'email@mail.com', 'contact_number' => '12345678' }, { 'contact_number' => '12323213' }] }

    it 'should update the user contact list and return all the matching users against the list' do
      user1 = create(:user, name: 'user1', email: 'email@mail.com')
      user2 = create(:user, name: 'user2', contact_number: '12323213')
      User.import

      v5_client_post '/contacts', authentication_token: user.authentication_token, email: user.email, contact_list: contact_list
      json_response do |attributes|
        expect(user.reload.contact_list).to eq(contact_list)
        expect(attributes['users'][0]['name']).to eq(user1.name)
        expect(attributes['users'][1]['name']).to eq(user2.name)
        expect(attributes['users'].count).to eq(2)
      end
    end
  end
end
