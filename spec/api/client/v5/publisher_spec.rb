require 'spec_helper'

module Api
  module Client
    module V5

      describe_client_api Publisher do
        describe 'GET /publisher/find' do
          let!(:user) { create(:user) }

          before { logged_in(user) }

          before do
            timeline = Timeline.new
            allow(timeline).to receive(:valid?) { true }
            allow(timeline).to receive(:save) { true }
            allow(TimelinesRecognize).to receive(:do) { timeline }
          end

          it 'recognize url and respond with timeline object' do
            v5_client_get "publisher/find", authentication_token: user.authentication_token, email: user.email, track: "Stan", artist: "Eminem"

            expect(response.status).to eq(200)
            expect(Timeline.count).to eq(0)
            json_response do |json|
              timeline_id = json['id']
              expect(timeline_id).not_to eq("0")
              timeline_marshal = Cache.get(timeline_id)
              expect(timeline_marshal).to be
              timeline = Marshal.load(timeline_marshal)
              expect(timeline).to be
            end
          end
        end

        describe 'GET /publisher/publish/:id' do
          let!(:user) { create(:user) }

          before { logged_in(user) }

          before do
            timeline = build(:timeline, user: user)
            allow(TimelinesRecognize).to receive(:do) { timeline }
          end

          it 'recognize url and respond with timeline object' do
            v5_client_get "publisher/find", authentication_token: user.authentication_token, email: user.email, track: "Stan", artist: "Eminem"

            json_response do |json|
              timeline_id = json['id']

              v5_client_post "publisher/publish/#{timeline_id}", authentication_token: user.authentication_token, email: user.email, track: "Stan", artist: "Eminem"
              expect(response.status).to eq(201)
            end
          end
        end

        describe 'GET /publisher/publish/:id for existing timeline' do
          let!(:user) { create(:user) }
          let!(:owner) { create(:user, facebook_id: 'new-facebook-id') }

          before { logged_in(user) }

          it 'recognize url and respond with timeline object' do
            timeline = create(:timeline, user: owner)

            v5_client_post "publisher/publish/#{timeline.id}", authentication_token: user.authentication_token, email: user.email, track: "Stan", artist: "Eminem"
            expect(response.status).to eq(201)
          end
        end
      end

    end
  end
end
