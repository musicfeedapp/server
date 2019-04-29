require 'spec_helper'

require 'spec_helper'

module Api
  module Client
    module V3

      describe_client_api Profile do

        describe 'GET /v3/profile/show?username=<ext_id>' do
          let!(:user) { create(:user) }

          before { logged_in(user) }

          it 'should get user details with playlist, followers, songs and followings count dependency for current user' do
            kate = create(:kate)
            fred = create(:fred)

            user.follow!(kate)
            kate.follow!(fred)
            kate.friend!(fred)
            playlist = create(:playlist, user_id: kate.id)

            v3_client_get "profile/show", authentication_token: user.authentication_token, email: user.email, username: kate.ext_id
            expect(response.status).to eq(200)
            json_response do |attributes|
              expect(attributes['username']).to eq(kate.username)
              expect(attributes['songs_count']).to eq(0)
              expect(attributes['playlists_count']).to eq(1)
              expect(attributes['followed_count']).to eq(1)
              expect(attributes['followings_count']).to eq(1)
            end
          end
        end

        describe 'GET /v3/profile/followers/show?username=<ext_id>' do
          let!(:user) { create(:user) }

          before { logged_in(user) }

          it 'should get user followers dependency for current user' do
            kate = create(:kate)
            fred = create(:fred)

            user.follow!(kate)
            user.follow!(fred)
            kate.follow!(fred)
            kate.friend!(fred)

            v3_client_get "profile/followers", authentication_token: user.authentication_token, email: user.email, username: kate.ext_id
            expect(response.status).to eq(200)
            json_response do |attributes|
              expect(attributes['followed'].to_a.size).to eq(1)
              expect(attributes['followed'][0]['username']).to eq(user.username)
              expect(attributes['followed'][0]['is_followed']).to eq(true)
            end

            v3_client_get "profile/followers", authentication_token: user.authentication_token, email: user.email, username: fred.ext_id
            expect(response.status).to eq(200)
            json_response do |attributes|
              expect(attributes['followed'].to_a.size).to eq(2)

              names = attributes['followed'].map { |a| a['username'] }
              expect(names).to include(user.username)
              expect(names).to include(kate.username)
            end
          end
        end

        describe 'GET /v3/profile/following/show?username=<ext_id>' do
          let!(:user) { create(:user) }

          before { logged_in(user) }

          it 'should get user artists, friends and is_followed flag as dependency for current user' do
            kate = create(:kate)
            fred = create(:fred)

            kate.follow!(fred)
            kate.friend!(fred)

            user.follow!(fred)

            v3_client_get "profile/following", authentication_token: user.authentication_token, email: user.email, username: kate.ext_id
            expect(response.status).to eq(200)
            json_response do |attributes|
              expect(attributes['followings']['artists'].to_a.size).to eq(0)
              expect(attributes['followings']['friends'][0]['username']).to eq(fred.username)
              expect(attributes['followings']['friends'][0]['is_followed']).to eq(true)
            end
          end

          it 'should get user artists, friends and is_followed flag as dependency for current user' do
            kate = create(:kate)
            fred = create(:fred)
            bob  = create(:artist, user_type: 'artist', facebook_id: "facebook_id1")

            fred.follow!(kate)
            fred.friend!(kate)
            fred.follow!(bob)
            user.follow!(bob)

            v3_client_get "profile/following", authentication_token: user.authentication_token, email: user.email, username: fred.ext_id
            expect(response.status).to eq(200)
            json_response do |attributes|
              expect(attributes['followings']['artists'][0]['username']).to eq(bob.username)
              expect(attributes['followings']['artists'][0]['is_followed']).to eq(true)
              expect(attributes['followings']['friends'][0]['username']).to eq(kate.username)
              expect(attributes['followings']['friends'][0]['is_followed']).to eq(false)
            end
          end
        end
      end
    end
  end
end

