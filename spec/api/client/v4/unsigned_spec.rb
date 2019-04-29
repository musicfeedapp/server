require 'spec_helper'

require 'sidekiq/testing'

module Api
  module Client
    module V4
      describe_client_api Unsigned do
        describe 'GET /' do
          it 'should return artist timelines' do
            user1, user2, timeline1, timeline2, timeline3 = nil, nil, nil, nil, nil

            Sidekiq::Testing.inline! do
              user1 = create(:artist, facebook_id: 'facebook-1', name: 'MIA')
              user2 = create(:artist, facebook_id: 'facebook-2', name: 'Bob Marley')

              timeline1 = create(:timeline, name: 'Static - X 1', user: user1)
              timeline2 = create(:timeline, name: 'Static - X 2', user: user1)
              timeline3 = create(:timeline, name: 'Static - X 3', user: user2)
            end

            v4_client_get "/unsigned/tracks", artists_ids: [user1.id], device_id: "123"
            json_response do |attributes|
              expect(attributes[0]['id']).to eq(timeline2.id)
              expect(attributes[1]['id']).to eq(timeline1.id)
              expect(attributes.size).to eq(2)
            end
          end
        end
      end
    end
  end
end
