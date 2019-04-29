require 'spec_helper'

describe_client_api Api::Client::V5::PhoneArtists do
  let!(:user) { create(:user) }
  before { logged_in(user) }

  describe 'POST /phone_artsts' do
    let!(:phone_artists) { [{ 'name' => 'artist1' }, { 'name' => 'artist2' }] }

    it 'should update the user phone_artists list and return all the matching phone artists the list' do
      artist = create(:artist, name: 'artist1')
      User.import

      v5_client_post '/phone_artists', authentication_token: user.authentication_token, email: user.email, phone_artists: phone_artists
      json_response do |attributes|
        expect(user.reload.phone_artists).to eq(phone_artists)

        artists_attributes = attributes["artists"]

        expect(artists_attributes.first['name']).to eq(artist.name)
        expect(artists_attributes.count).to eq(1)
      end
    end
  end
end
