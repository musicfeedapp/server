require 'spec_helper'

require 'sidekiq/testing'

module Api
  module Client
    module V2

      describe_client_api Search do

        describe 'GET /v2/search' do
          let!(:user) do
            user = nil

            Sidekiq::Testing.inline! do
              user = create(:user, facebook_id: 'facebook-1')
            end

            user
          end

          before { logged_in(user) }

          it 'should returns is_followed flag depends on the status for user' do
            user2 = nil
            Sidekiq::Testing.inline! do
              user2 = create(:user, facebook_id: 'facebook-2', name: 'Bob')
            end

            allow_any_instance_of(User).to receive(:friend_search).and_return(
              double('pagination').tap { |proxy|
                allow(proxy).to receive(:per) {
                  double('scope', records: User.where(id: user2.id))
                }
              }
            )

            v2_client_get "search", authentication_token: user.authentication_token, email: user.email, keywords: 'bob', search_type: 'users'
            expect(response.status).to eq(200)
            json_response do |attributes|
              expect(attributes['users'][0]['is_followed']).to eq(false)
            end

            user.follow!(user2)

            v2_client_get "search", authentication_token: user.authentication_token, email: user.email, keywords: 'bob', search_type: 'users'
            expect(response.status).to eq(200)
            json_response do |attributes|
              expect(attributes['users'][0]['is_followed']).to eq(true)
            end
          end

          it 'should skip artists with no posts' do
            user2 = nil

            Sidekiq::Testing.inline! do
              user2 = create(:artist, facebook_id: 'facebook-2', name: 'Bob Marley')
            end

            allow_any_instance_of(User).to receive(:artist_search).and_return(
              double('pagination').tap { |proxy|
                allow(proxy).to receive(:per) {
                  double('scope', records: User.where(id: user2.id))
                }
              }
            )

            v2_client_get "search", authentication_token: user.authentication_token, email: user.email, keywords: 'bob', search_type: 'artists'
            expect(response.status).to eq(200)
            json_response do |attributes|
              expect(attributes['artists'][0]).to eq(nil)
            end
          end

          it 'should returns is_followed flag depends on the status for user' do
            user2 = nil

            Sidekiq::Testing.inline! do
              user2 = create(:artist, facebook_id: 'facebook-2', name: 'Bob Marley')
              create(:timeline, user: user2)
            end

            allow_any_instance_of(User).to receive(:artist_search).and_return(
              double('pagination').tap { |proxy|
                allow(proxy).to receive(:per) {
                  double('scope', records: User.where(id: user2.id))
                }
              }
            )

            v2_client_get "search", authentication_token: user.authentication_token, email: user.email, keywords: 'bob', search_type: 'artists'

            expect(response.status).to eq(200)
            json_response do |attributes|
              expect(attributes['artists'][0]['is_followed']).to eq(false)
            end

            user.follow!(user2)

            v2_client_get "search", authentication_token: user.authentication_token, email: user.email, keywords: 'bob', search_type: 'artists'
            expect(response.status).to eq(200)
            json_response do |attributes|
              expect(attributes['artists'][0]['is_followed']).to eq(true)
            end
          end

          it 'should returns is_followed flag depends on the status for user' do
            user2, timeline21, timeline22 = nil, nil, nil

            Sidekiq::Testing.inline! do
              user2 = create(:artist, facebook_id: 'facebook-2', name: 'Bob Marley')
              timeline21 = create(:timeline, name: 'Static - X 1', user: user2)
              timeline22 = create(:timeline, name: 'Static - X 2', user: user2)
            end

            user.like!(timeline22)

            allow(Timeline).to receive(:search) {
              double('pagination').tap { |proxy|
                allow(proxy).to receive(:per) {
                  double('scope', records: Timeline.where(id: [timeline21.id, timeline22.id]))
                }
              }
            }

            v2_client_get "search", authentication_token: user.authentication_token, email: user.email, keywords: 'static', search_type: 'timelines'
            expect(response.status).to eq(200)
            json_response do |attributes|
              timelines = attributes['timelines']
              expect(timelines.find { |t| t['id'] == timeline21.id }['is_liked']).to eq(false)
              expect(timelines.find { |t| t['id'] == timeline22.id }['is_liked']).to eq(true)
            end
          end

        end

      end


    end
  end
end
