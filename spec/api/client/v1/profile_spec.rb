require 'spec_helper'

describe_client_api Api::Client::V1::Profile do

  describe 'GET /profile/:username of artist' do
    let!(:user) { create(:user) }

    before { logged_in(user) }

    let!(:artist) { create(:artist, username: 'BobMarley') }

    it 'finds bob marley as artist and respond ok' do
      client_get "profile/#{artist.username}", authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(200)
    end
  end

  describe 'GET /profile' do
    let!(:user) { create(:user) }

    it 'should have timeline routable path' do
      client_get 'profile', authentication_token: user.authentication_token, email: user.email
      expect(response.status).not_to eq(404)
    end

    it 'should respond with bad request in case of the missing auth params' do
      client_get 'profile', authentication_token: user.authentication_token
      expect(response.status).to eq(400)
      client_get 'profile', email: user.email
      expect(response.status).to eq(400)
    end

    it 'returns number of suggestions' do
      bob = create(:artist, name: 'Bob', facebook_id: '1')
      create(:timeline, user: bob)
      create(:timeline, user: bob)

      create(:artist, name: 'Kate', facebook_id: '2')

      watson = create(:artist, name: 'Watson', facebook_id: '3')
      create(:timeline, user: watson)

      client_get 'profile', authentication_token: user.authentication_token, email: user.email

      json_response do |json|
        # TODO: we should replace this number later by real suggestions count number.
        # expect(json['suggestions_count']).to eq(2)
      end
    end

    it "should return list of the all user's timelines" do
      client_get 'profile', authentication_token: user.authentication_token, email: user.email
      json_response do |json|
        expect(json['email']).to               eq(user.email)
        expect(json['name']).to                eq(user.name)
        expect(json['first_name']).to          eq(user.first_name)
        expect(json['last_name']).to           eq(user.last_name)
        expect(json['profile_image']).to       eq(user.profile_image)
        expect(json['facebook_link']).to       eq(user.facebook_link)
        expect(json['is_facebook_expired']).to eq(false)
      end
    end

    context 'with user followed users' do
      let!(:kate)   { create(:kate) }
      let!(:fred)   { create(:fred) }
      let!(:mario)  { create(:mario) }

      it 'should have the right number of the followed users' do
        kate.follow!(user)
        fred.follow!(user)

        # Other follow! actions for checking the number of followed users for
        # authenticated user.
        mario.follow!(fred)
        mario.follow!(kate)

        client_get 'profile', authentication_token: user.authentication_token, email: user.email
        json_response do |json|
          expect(json['followed_count']).to eq(2)
        end
      end

    end

    context 'with user songs count' do
      let!(:user) { create(:kate) }

      let!(:timeline1) { create(:timeline, user: user) }
      let!(:timeline2) { create(:timeline, user: user) }

      before do
        timeline1.update_attributes(user: user)
        timeline2.update_attributes(user: user)
      end

      it 'should return the number of the user songs' do
        client_get 'profile', authentication_token: user.authentication_token, email: user.email
        json_response do |json|
          expect(json['songs_count']).to eq(2)
        end
      end
    end

    context 'with friends' do
      let!(:user) { create(:user) }

      let!(:user2) { create(:user, user_type: 'user') }
      let!(:user3) { create(:user, user_type: 'artist') }

      before do
        user.friend!(user2)
        user.follow!(user3)
        user.follow!(user2)
      end

      it 'returns followings list on profile request as well' do
        client_get 'profile', authentication_token: user.authentication_token, email: user.email
        json_response do |json|
          expect(json['followings']).to be
          expect(json['followings']['friends']).to have(1).items
          expect(json['followings']['friends'][0]['is_followed']).to eq(true)
          expect(json['followings']['artists']).to have(1).items
          expect(json['followings']['artists'][0]['is_followed']).to eq(true)
        end
      end
    end

    context 'with followings' do
      let!(:user) { create(:user) }

      let!(:user2) { create(:user, user_type: 'user') }
      let!(:user3) { create(:user, user_type: 'artist') }

      before do
        user.follow!(user2)
        user.follow!(user3)
      end

      it 'returns followings list on profile request as well' do
        client_get 'profile', authentication_token: user.authentication_token, email: user.email
        json_response do |json|
          expect(json['followings']).to be
          expect(json['followings']['friends']).to have(1).items
          expect(json['followings']['friends'][0]['is_followed']).to eq(true)
          expect(json['followings']['artists']).to have(1).items
          expect(json['followings']['artists'][0]['is_followed']).to eq(true)
        end
      end
    end

    context 'with followed' do
      let!(:user) { create(:user) }
      let!(:kate) { create(:kate) }
      let!(:fred) { create(:fred) }

      before do
        user.follow!(kate)
        user.follow!(fred)
        kate.follow!(user)
      end

      it 'returns followings list on profile request as well' do
        client_get 'profile', authentication_token: user.authentication_token, email: user.email
        json_response do |json|
          expect(json['followed']).to have(1).item
          expect(json['followed'][0]['is_followed']).to eq(true)
          expect(json['followings']['friends']).to have(2).items
        end
      end
    end

    context 'sort friends/artists by songs count' do
      it 'should sort profile friends by songs count' do
        user1 = create(:user, facebook_id: 'facebook-11')
        timeline1 = create(:timeline, user: user1)
        timeline2 = create(:timeline, user: user1)

        user2 = create(:user, facebook_id: 'facebook-22')
        timeline3 = create(:timeline, user: user2)

        user3 = create(:user, facebook_id: 'facebook-33')
        timeline4 = create(:timeline, user: user3)
        timeline5 = create(:timeline, user: user3)
        timeline6 = create(:timeline, user: user3)

        user.follow!(user1)
        user.follow!(user2)
        user.follow!(user3)

        expect(user1.reload.timelines_count).to eq(2)
        expect(user2.reload.timelines_count).to eq(1)
        expect(user3.reload.timelines_count).to eq(3)

        client_get 'profile', authentication_token: user.authentication_token, email: user.email
        json_response do |json|
          friend_ids = json['followings']['friends'].map { |attributes| attributes['facebook_id'] }
          expect(friend_ids).to have(3).items
          expect(friend_ids[0]).to eq(user3.identifier)
          expect(friend_ids[1]).to eq(user1.identifier)
          expect(friend_ids[2]).to eq(user2.identifier)
        end
      end

      it 'should sort profile artists by songs count' do
        user1 = create(:artist, facebook_id: 'facebook-11')
        timeline1 = create(:timeline, user: user1)
        timeline2 = create(:timeline, user: user1)

        user2 = create(:artist, facebook_id: 'facebook-22')
        timeline3 = create(:timeline, user: user2)

        user3 = create(:artist, facebook_id: 'facebook-33')
        timeline4 = create(:timeline, user: user3)
        timeline5 = create(:timeline, user: user3)
        timeline6 = create(:timeline, user: user3)

        user.follow!(user1)
        user.follow!(user2)
        user.follow!(user3)

        expect(user1.reload.timelines_count).to eq(2)
        expect(user2.reload.timelines_count).to eq(1)
        expect(user3.reload.timelines_count).to eq(3)

        client_get 'profile', authentication_token: user.authentication_token, email: user.email
        json_response do |json|
          friend_ids = json['followings']['artists'].map { |attributes| attributes['facebook_id'] }
          expect(friend_ids).to have(3).items
          expect(friend_ids[0]).to eq(user3.identifier)
          expect(friend_ids[1]).to eq(user1.identifier)
          expect(friend_ids[2]).to eq(user2.identifier)
        end
      end
    end

  end

  describe 'GET /profile/:username' do
    let(:user) { create(:user, name: 'Bill Name') }

    before { logged_in(user) }

    it 'should respond for user normally' do
      kate = create(:kate, username: 'KateWatson')

      client_get "profile/#{kate.username}", authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(200)
      json_response do |attributes|
        expect(attributes['username']).to eq(kate.username)
      end
    end

    it 'should return playlists in the profile as well' do
      kate = create(:kate, username: 'KateWatson')
      playlist = create(:playlist, user: kate)

      client_get "profile/#{kate.username}", authentication_token: user.authentication_token, email: user.email

      json_response do |attributes|
        expect(attributes['playlists']).to have(3).item
        # default, liked, and `playlist`
      end
    end

    it 'should respond for artist normally' do
      bob = create(:artist, username: 'BobMarley', facebook_id: 'bob_marley')
      timeline = create(:timeline, user: bob, user: bob)

      client_get "profile/#{bob.username}", authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(200)
      json_response do |attributes|
        expect(attributes['username']).to eq(bob.username)
        expect(attributes['songs']).to have(1).item
        expect(attributes['songs'][0]['name']).to eq(timeline.name)
      end
    end

    it 'should track is_followed flag' do
      user1 = create(:user, name: 'user1', facebook_id: 'facebook-11')
      user2 = create(:user, name: 'user2', facebook_id: 'facebook-22')

      user.follow!(user1)

      client_get "profile/#{user1.username}", authentication_token: user.authentication_token, email: user.email
      json_response do |attributes|
        expect(attributes['is_followed']).to eq(true)
      end

      client_get "profile/#{user2.username}", authentication_token: user.authentication_token, email: user.email
      json_response do |attributes|
        expect(attributes['is_followed']).to eq(false)
      end
    end
  end

end
