require 'spec_helper'

describe_client_api Api::Client::V5::Users do
  include Rack::Test::Methods

  let!(:user) { create(:user, secondary_phones: [ "12312321", "12321321" ], secondary_emails: [ "foo@test.com", "foobar@test.com" ]) }
  before { logged_in(user) }

  describe 'PUT /update_profile' do
    it 'should update the user attributes and return updated user' do
      v5_client_put '/users/update_profile', authentication_token: user.authentication_token, email: user.email,
                                             user: { username: "foobar",
                                                     secondary_phones: [ "6361249", "6800683" ],
                                                     secondary_emails: [ "foo@testing.com", "foobar@testing.com" ],
                                                     avatar: Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/musicfeed_logo.png"), 'image/png')
                                                   }

      json_response do |attributes|
        expect(user.reload.username).to eq(attributes['username'])
        expect(user.reload.secondary_phones).to eq(attributes['secondary_phones'])
        expect(user.reload.secondary_emails).to eq(attributes['secondary_emails'])
        expect(user.reload.avatar.url).to eq(attributes['avatar_url'])
        expect(user.reload.profile_image).to eq(attributes['profile_image'])
      end
    end
  end

  describe 'PUT /restrict_suggestion' do
    it 'should update the user attributes and return updated user' do
      user1 = create(:user, ext_id: 'ext-1')
      user2 = create(:user, ext_id: 'ext-2')

      v5_client_put '/users/restrict_suggestion', authentication_token: user.authentication_token, email: user.email, user_ext_id: user1.ext_id
      expect(user.reload.restricted_suggestions).to include(user1.id.to_s)
      expect(user.reload.restricted_suggestions.size).to eq(1)

      v5_client_put '/users/restrict_suggestion', authentication_token: user.authentication_token, email: user.email, user_ext_id: user2.ext_id
      expect(user.reload.restricted_suggestions).to include(user2.id.to_s)
      expect(user.reload.restricted_suggestions.size).to eq(2)

      # no duplicates in array
      v5_client_put '/users/restrict_suggestion', authentication_token: user.authentication_token, email: user.email, user_ext_id: user2.ext_id
      expect(user.reload.restricted_suggestions.size).to eq(2)
    end
  end
end
