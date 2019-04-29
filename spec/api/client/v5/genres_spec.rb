require 'spec_helper'

describe_client_api Api::Client::V5::Genres do
  let!(:user) { create(:user) }
  before { logged_in(user) }

  describe 'GET /index' do
    it 'should return all the genres' do
      genre1 = create(:genre)
      genre2 = create(:genre, name: "rock")
      genre3 = create(:genre, name: "trance")

      UserGenre.create(user_id: user.id, genre_id: Genre.first.id)

      v5_client_get "/genres/index", email: user.email, authentication_token: user.authentication_token
      json_response do |attributes|
        expect(attributes.count).to eq(1)
      end
    end
  end

  describe 'GET /index' do
    it 'should return all the genres' do
      genre1 = create(:genre)
      genre2 = create(:genre, name: "rock")
      genre3 = create(:genre, name: "trance")

      v5_client_post "/genres/user_genres", email: user.email, authentication_token: user.authentication_token, genre_ids: [ genre1.id, genre2.id, genre3.id ]
      json_response do |attributes|
        expect(user.genres).to include(genre1)
        expect(user.genres).to include(genre2)
        expect(user.genres).to include(genre3)

        expect(user.user_genres.count).to eq(3)
        expect(user.genres.count).to eq(3)
      end
    end
  end
end
