require 'spec_helper'

describe_client_api Api::Client::V1::Songs, broken: true do
  include UserMocks

  let!(:user) { create(:user) }

  describe 'GET /songs' do
    before { logged_in(user) }

    before do
      user.songs << create(:timeline, user_identifier: user.facebook_id)
      user.songs << create(:timeline, user_identifier: user.facebook_id)
    end

    let(:songs) { user.songs }

    it 'should respond with bad request in case of the missing auth params' do
      client_get 'songs', authentication_token: user.authentication_token
      expect(response.status).to eq(400)
      client_get 'songs', email: user.email
      expect(response.status).to eq(400)
    end

    it 'should have songs routable path' do
      client_get 'songs', authentication_token: user.authentication_token, email: user.email
      expect(response.status).not_to eq(404)
    end

    it 'should be possible to get list of the stars songs' do
      client_get 'songs', authentication_token: user.authentication_token, email: user.email
      json_response do |json|
        expect(json).to have(2).items
        json.each do |song|
          expect(song.keys).to include('name')
          expect(song.keys).to include('album')
          expect(song.keys).to include('artist')
          expect(song.keys).to include('picture')
          expect(song.keys).to include('author')
          expect(song.keys).to include('author_picture')
          expect(song.keys).to include('link')
          expect(song.keys).to include('likes_count')
          expect(song.keys).to include('youtube_link')
          expect(song.keys).to include('published_at')
          expect(song.keys).to include('username')
          expect(song.keys).to include('font_color')
        end
      end
    end

    it 'should return the specific format for the published at date' do
      client_get 'songs', authentication_token: user.authentication_token, email: user.email
      json_response do |json|
        published_ats = json.map {|song| song['published_at']}
        json.each do |timeline|
          expect(published_ats).to include(songs[0].published_at.as_json) # 2014-04-15T11:20:59.903Z
          expect(published_ats).to include(songs[1].published_at.as_json) # 2014-04-15T11:20:59.903Z
        end
      end
    end

  end

  describe 'POST /songs/:timeline_id' do
    let!(:timeline) { create(:timeline) }

    it 'should respond with bad request in case of the missing auth params' do
      client_post 'songs', timeline_id: timeline.id, authentication_token: user.authentication_token
      expect(response.status).to eq(400)
      client_post 'songs', timeline_id: timeline.id, email: user.email
      expect(response.status).to eq(400)
    end

    it 'should add a song to the user by timeline id' do
      client_post 'songs', timeline_id: timeline.id, authentication_token: user.authentication_token, email: user.email
      user.reload
      expect(user.user_songs).to have(1).item
      expect(user.user_songs[0].user_id).to eq(user.id)
      expect(user.user_songs[0].timeline_id).to eq(timeline.id)
    end

    it 'should not duplicate the songs in multiple requests' do
      2.times { client_post 'songs', timeline_id: timeline.id, authentication_token: user.authentication_token, email: user.email }
      user.reload
      expect(user.user_songs).to have(1).item
      expect(response.status).to eq(201)
    end
  end

  describe 'DELETE /songs/:id' do
    let(:timeline) { create(:timeline) }

    before do
      user.songs << timeline
    end

    it 'should respond with bad request in case of the missing auth params' do
      client_delete "songs/#{timeline.id}", authentication_token: user.authentication_token
      expect(response.status).to eq(400)
      client_delete "songs/#{timeline.id}", email: user.email
      expect(response.status).to eq(400)
    end

    it 'should add a song to the user by timeline id' do
      client_delete "songs/#{timeline.id}", authentication_token: user.authentication_token, email: user.email
      user.reload
      expect(user.songs).to be_empty
    end
  end
end

