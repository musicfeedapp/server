require 'spec_helper'

describe_client_api Api::Client::V1::Playlists do
  describe 'GET /playlists' do
    let!(:user) { create(:user) }

    before { logged_in(user) }

    it 'should returns playlists for current user' do
      playlist1 = create(:playlist, user: user)
      playlist2 = create(:playlist, user: user)

      user2 = create(:user)
      playlist3 = create(:playlist, user: user2)

      client_get "playlists", authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(200)

      json_response do |json|
        expect(json).to have(4).items

        playlist_ids = json.map { |attributes| attributes['id'] }
        expect(playlist_ids).to include(playlist1.id)
        expect(playlist_ids).to include(playlist2.id)
        expect(playlist_ids).to include('default')
        expect(playlist_ids).to include('likes')
      end
    end

    it 'should not be possible to get private playlists' do
      user1 = create(:user)
      playlist1 = create(:playlist, user: user1, is_private: false)

      user2 = create(:user)
      playlist2 = create(:playlist, user: user2, is_private: false)

      # user1
      client_get "playlists", authentication_token: user1.authentication_token, email: user1.email
      expect(response.status).to eq(200)

      json_response do |json|
        playlist_ids = json.map { |attributes| attributes['id'] }
        expect(playlist_ids.size).to eq(3)
        expect(playlist_ids).to include(playlist1.id)
        expect(playlist_ids).to include('default')
        expect(playlist_ids).to include('likes')
      end

      playlist1.update_attributes!(is_private: true)
      playlist2.update_attributes!(is_private: true)

      # user2
      client_get "playlists", authentication_token: user1.authentication_token, email: user1.email, ext_id: user2.ext_id
      expect(response.status).to eq(200)

      json_response do |json|
        playlist_ids = json.map { |attributes| attributes['id'] }
        expect(playlist_ids.size).to eq(2)
        expect(playlist_ids).to include('default')
        expect(playlist_ids).to include('likes')
      end
    end
  end

  describe 'POST /playlists' do
    let!(:user) { create(:user) }

    before { logged_in(user) }

    it 'should returns playlists for current user' do
      client_post "playlists", title: 'title1', authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(201)

      json_response do |json|
        expect(json['title']).to eq('title1')
      end
    end
  end

  describe 'PUT /playlists/:id/private' do
    let!(:user) { create(:user, timelines_count: 10,
                          private_playlists_timelines_count: 10,
                          public_playlists_timelines_count: 20) }

    before { logged_in(user) }

    it 'should returns playlists for current user' do
      playlist = create(:playlist, user: user, is_private: false, timelines_ids: [1, 3, 4, 5])

      client_put "playlists/#{playlist.id}", is_private: true, authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(200)

      json_response do |json|
        expect(user.reload.private_playlists_timelines_count).to eq(14)
        expect(user.reload.public_playlists_timelines_count).to eq(16)
        expect(json['is_private']).to eq(true)
      end

      client_put "playlists/#{playlist.id}", is_private: false, authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(200)

      json_response do |json|
        expect(user.reload.private_playlists_timelines_count).to eq(10)
        expect(user.reload.public_playlists_timelines_count).to eq(20)
        expect(json['is_private']).to eq(false)
      end
    end
  end

  describe 'DELETE /playlists/:id' do
    let!(:user) { create(:user) }

    before { logged_in(user) }

    it 'should returns playlists for current user' do
      playlist = create(:playlist, user: user)
      client_delete "playlists/#{playlist.id}", authentication_token: user.authentication_token, email: user.email
      expect(Playlist.count).to eq(0)
    end
  end

  describe 'POST /playlists/:id/add' do
    let!(:user) { create(:user, facebook_id: 'facebook-1') }

    before { logged_in(user) }

    it 'should create comments for timelines' do
      playlist = create(:playlist, user: user)
      timeline1 = create(:timeline, user: user)
      timeline1.activities.destroy_all

      client_post "playlists/#{playlist.id}/add", timelines_ids: [timeline1.id], authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(201)

      comments = timeline1.reload.activities.to_a
      expect(comments.size).to eq(1)
      expect(comments[0].user_id).to eq(user.id)
      expect(comments[0].eventable_type).to eq(playlist.class.name)
      expect(comments[0].eventable_id).to eq(playlist.id.to_s)
    end

    it 'should create comments for recognized timelines' do
      Timeline.destroy_all
      Comment.destroy_all

      timeline = build(:timeline, user: user)
      timeline.custom_id = SecureRandom.uuid
      Cache.set(timeline.custom_id, Marshal.dump(timeline))

      playlist = create(:playlist, user: user)
      client_post "playlists/#{playlist.id}/add", timelines_ids: [timeline.custom_id], authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(201)

      expect(Timeline.count).to eq(1)

      comments = Timeline.first.activities.to_a
      expect(comments.size).to eq(2)
      expect(comments[0].user_id).to eq(user.id)
      expect(comments[1].user_id).to eq(user.id)

      timeline = Timeline.first

      comment = comments.detect { |c| c.eventable_type == 'Playlist' }
      expect(comment.commentable_id.to_i).to eq(timeline.id)
      expect(comment.eventable_id.to_i).to eq(playlist.id)

      comment = comments.detect { |c| c.eventable_type == 'Timeline' }
      expect(comment.commentable_id.to_i).to eq(timeline.id)
    end

    it 'should returns playlists for current user' do
      playlist = create(:playlist, user: user)
      timeline1 = create(:timeline, user: user)
      timeline1.activities.destroy_all

      timeline2 = create(:timeline, user: user)
      timeline2.activities.destroy_all

      timeline3 = create(:timeline, user: user)
      timeline3.activities.destroy_all

      client_post "playlists/#{playlist.id}/add", timelines_ids: [timeline1.id, timeline2.id], authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(201)

      playlist.reload
      playlist.current_user = user

      timelines, _activities, _publishers  = playlist.timelines

      expect(timelines).to have(2).items

      timelines_ids = timelines.map { |attributes| attributes['id'] }
      expect(timelines_ids).to include(timeline1.id)
      expect(timelines_ids).to include(timeline2.id)
    end

    it 'should be possible to remove timelines from liked playlist' do
      timeline1 = create(:timeline, user: user)

      user.like!(timeline1.id)

      playlist = ::Playlists::Likes.new(user)
      playlist.current_user = user
      playlist.params = {}
      timelines, _activities, _publishers  = playlist.timelines
      expect(timelines).to eq([timeline1])

      # remove timelines from default playlist
      client_delete "playlists/likes/remove", timelines_ids: [timeline1.id], authentication_token: user.authentication_token, email: user.email

      playlist = ::Playlists::Likes.new(user)
      playlist.current_user = user
      playlist.params = {}
      timelines, _activities, _publishers  = playlist.timelines

      expect(timelines.size).to eq(0)
    end
  end

  describe 'DELETE /playlists/:id/remove' do
    let!(:user) { create(:user) }

    before { logged_in(user) }

    it 'should returns playlists for current user' do
      timeline1 = create(:timeline, user: user)

      playlist = create(:playlist, user: user, timelines_ids: [timeline1.id])
      expect(playlist.reload.timelines_ids).to have(1).item

      client_delete "playlists/#{playlist.id}/remove", timelines_ids: [timeline1.id], authentication_token: user.authentication_token, email: user.email

      timelines, _activites, _publishers = playlist.reload.timelines
      expect(timelines).to have(0).items
    end
  end

  describe 'GET /playlists/:id' do
    let!(:user) { create(:user) }

    before { logged_in(user) }

    it 'should returns timelines from the playlist' do
      timeline1 = create(:timeline, user: user)
      timeline2 = create(:timeline, user: user)
      timeline3 = create(:timeline, user: user)

      playlist = create(:playlist, user: user, timelines_ids: [timeline1.id, timeline2.id])
      expect(playlist.reload.timelines_ids).to have(2).items

      client_get "playlists/#{playlist.id}", authentication_token: user.authentication_token, email: user.email

      json_response do |json|
        expect(json['tracks_count']).to eq(2)

        timelines = json['songs']
        expect(timelines).to have(2).items

        timelines_ids = timelines.map { |attributes| attributes['id'] }
        expect(timelines_ids).to include(timeline1.id)
        expect(timelines_ids).to include(timeline2.id)
      end
    end
  end
end
