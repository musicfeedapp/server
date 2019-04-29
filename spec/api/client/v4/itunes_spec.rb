require 'spec_helper'
module Api
  module Client
    module V4
      describe_client_api Itunes do
        describe 'GET /v4/itunes' do
          let!(:user) { create(:user) }

          before { logged_in(user) }

          it 'returns 400 error without a list of tracks' do
            v4_client_get 'itunes', email: user.email, authentication_token: user.authentication_token
            expect(response.status).to eq(400)
          end

          it 'returns a list of matching artists given a list of tracks' do
            artist = create(:artist)
            allow_any_instance_of(User).to receive(:multiple_artist_search).and_return([artist])

            genre = Genre.create!(name: "Rock")
            UserGenre.create!(user_id: artist.id, genre_id: genre.id)

            v4_client_get 'itunes', artists: ['Radiohead'], email: user.email, authentication_token: user.authentication_token
            expect(response.status).to eq(200)

            json_response do |json|
              expect(json).to have(1).item
              attributes = json[0]
              expect(attributes['id']).to eq(artist.id)
              expect(attributes['facebook_id']).to eq(artist.facebook_id)
              expect(attributes['facebook_link']).to eq(artist.facebook_link)
              expect(attributes['twitter_link']).to eq(artist.twitter_link)
              expect(attributes['avatar_url']).to eq(artist.profile_image)
              expect(attributes['name']).to eq(artist.name)
              expect(attributes['username']).to eq(artist.username)
              expect(attributes['genres']).to eq(["Rock"])
            end
          end
        end
      end
    end
  end
end
