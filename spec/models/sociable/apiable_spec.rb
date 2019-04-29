require 'spec_helper'

describe User do

  describe '.find_or_create_by_facebook_auth_token' do
    it 'should merge users in case of registering existing users' do
      # in case of having friend's user
      user1 = create(:user, first_name: 'Alex', last_name: 'Korsak', email: '123456@facebook.com')

      # Ensure that we don't have authentications for facebook provider.
      user1.authentications.destroy_all

      attributes = {
        id: user1.facebook_id,
        link: 'http://www.facebook.com/123123',
        email: 'alex.korsak@gmail.com',
        first_name: 'Alex',
        last_name: 'Korsak',
      }.with_indifferent_access

      allow_any_instance_of(Koala::Facebook::API).to receive(:get_object) { attributes }
      allow_any_instance_of(Koala::Facebook::OAuth).to receive(:exchange_access_token_info) { { 'access_token' => 'new-token' } }

      user2, _ = User.find_or_create_by_facebook_auth_token('auth-token')
      expect(user1.id).to eq(user2.id)
      expect(user2.reload.authentications).to be_present
      expect(user2.reload.email).to eq('alex.korsak@gmail.com')
      expect(user2.reload.authentications.last.auth_token).to eq('new-token')
    end

    it 'should also merge the user based on device id' do
      # in case of having friend's user
      user1 = create(:user, email: '123456@facebook.com', device_id: 'ABC12345GEFD', facebook_id: nil, facebook_link: nil)

      attributes = {
        id: '123212132131',
        link: 'http://www.facebook.com/123123',
        email: 'alex.korsak@gmail.com',
        first_name: 'Alex',
        last_name: 'Korsak',
      }.with_indifferent_access

      allow_any_instance_of(Koala::Facebook::API).to receive(:get_object) { attributes }
      allow_any_instance_of(Koala::Facebook::OAuth).to receive(:exchange_access_token_info) { { 'access_token' => 'new-token' } }

      user2, _ = User.find_or_create_by_facebook_auth_token('auth-token', device_id: user1.device_id)

      expect(user2.reload.authentications).to be_present
      expect(user2.reload.attributes).to eq(user1.reload.attributes)
    end
  end

end
