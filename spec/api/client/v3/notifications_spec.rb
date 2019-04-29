require 'spec_helper'

require 'spec_helper'

module Api
  module Client
    module V3
      describe_client_api Notifications do
        describe 'GET /' do
          let!(:user) { create(:user) }

          before { logged_in(user) }
          it 'finds user and respond ok' do
            v3_client_get "notifications", authentication_token: user.authentication_token, email: user.email
            expect(response.status).to eq(200)
          end

          it 'should return notification with alert type follow' do
            user2 = create(:user, facebook_id: 'facebook-2', name: 'Bob')

            user2.follow!(user)
            create(:user_notification, to_user_id: user.id, from_user_id: user2.id, alert_type: "follow")

            v3_client_get "/notifications", authentication_token: user.authentication_token, email: user.email
            json_response do |attributes|
              expect(attributes.first['user'].keys).to include('id')
              expect(attributes.first['user'].keys).to include('profile_image')
              expect(attributes.first['alert_type']).to eq("follow")
              expect(attributes.first['user']['name']).to eq("Bob")
            end
          end

          it 'should return notification with alert type like' do
            user2 = create(:user, facebook_id: 'facebook-2', name: 'Bob')
            timeline = create(:timeline, user: user)
            user2.like!(timeline)
            create(:user_notification, to_user_id: user.id, from_user_id: user2.id, alert_type: "like", timeline_id: timeline.id)

            v3_client_get "/notifications", authentication_token: user.authentication_token, email: user.email
            json_response do |attributes|
              expect(attributes.first['user'].keys).to include('id')
              expect(attributes.first['user'].keys).to include('profile_image')
              expect(attributes.first['alert_type']).to eq("like")
              expect(attributes.first['timeline']['name']).to eq(timeline.name)
              expect(attributes.first['user']['name']).to eq("Bob")
            end
          end

          it 'should return notification with alert type add_comment' do
            user2 = create(:user, facebook_id: 'facebook-2', name: 'Bob')
            timeline = create(:timeline, user: user)
            comment = timeline.comments.create(comment: 'comment1', user: user2)

            create(:user_notification, to_user_id: user.id, from_user_id: user2.id, alert_type: "add_comment", timeline_id: timeline.id, comment_id: comment.id, message: "comment1")

            v3_client_get "/notifications", authentication_token: user.authentication_token, email: user.email
            json_response do |attributes|
              expect(attributes.first['user'].keys).to include('id')
              expect(attributes.first['user'].keys).to include('profile_image')
              expect(attributes.first['alert_type']).to eq("add_comment")
              expect(attributes.first['user']['name']).to eq("Bob")
              expect(attributes.first['comment']['comment']).to eq("comment1")
            end
          end

          it 'should return notification with alert type add_to_playlist' do
            user2 = create(:user, facebook_id: 'facebook-2', name: 'Bob')
            timeline = create(:timeline, user: user)
            playlist = create(:playlist, title: "playlist1", user: user2, timelines_ids: [timeline.id])

            create(:user_notification, to_user_id: user.id, from_user_id: user2.id, alert_type: "add_to_playlist", timeline_id: timeline.id, playlist_id: playlist.id)

            v3_client_get "/notifications", authentication_token: user.authentication_token, email: user.email
            json_response do |attributes|
              expect(attributes.first['user'].keys).to include('id')
              expect(attributes.first['user'].keys).to include('profile_image')
              expect(attributes.first['alert_type']).to eq("add_to_playlist")
              expect(attributes.first['playlist']['title']).to eq("playlist1")
            end
          end
        end

        describe 'POST /notifications/read_all' do
          let!(:user) { create(:user) }

          before { logged_in(user) }

          it 'should update all the notifications' do
            
            user2 = create(:user, facebook_id: 'facebook-2', name: 'Bob')
            timeline = create(:timeline, user: user)
            playlist = create(:playlist, title: "playlist1", user: user2, timelines_ids: [timeline.id])
            
            comment = timeline.comments.create(comment: 'comment1', user: user2)
            
            notify1 = create(:user_notification, to_user_id: user.id, from_user_id: user2.id, alert_type: "add_comment", timeline_id: timeline.id, comment_id: comment.id, message: "comment1")
            notify2 = create(:user_notification, to_user_id: user.id, from_user_id: user2.id, alert_type: "add_to_playlist", timeline_id: timeline.id, playlist_id: playlist.id)

            v3_client_post "/notifications/read_all", authentication_token: user.authentication_token, email: user.email, notifications_ids: [notify1.id, notify2.id]
            json_response do |attributes|
              expect(attributes.to_a.size).to eq(2)
              expect(attributes[0]['alert_type']).to eq("add_comment")
              expect(attributes[0]['status']).to eq('read')
              expect(attributes[1]['alert_type']).to eq("add_to_playlist")
              expect(attributes[1]['status']).to eq('read')
            end
          end
        end

        describe 'POST /notifications/read' do
          let!(:user) { create(:user) }

          before { logged_in(user) }

          it 'should update given notification' do
            user2 = create(:user, facebook_id: 'facebook-2', name: 'Bob')
            timeline = create(:timeline, user: user)
            comment = timeline.comments.create(comment: 'comment1', user: user2)
            notify1 = create(:user_notification, to_user_id: user.id, from_user_id: user2.id, alert_type: "add_comment", timeline_id: timeline.id, comment_id: comment.id, message: "comment1")
            v3_client_post "/notifications/read", authentication_token: user.authentication_token, email: user.email, notification_id: notify1.id
            json_response do |attributes|
              expect(attributes['alert_type']).to eq("add_comment")
              expect(attributes['status']).to eq('read')
            end
          end
        end
      end
    end
  end
end
