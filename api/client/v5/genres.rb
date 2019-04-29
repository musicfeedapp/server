module Api
  module Client
    module V5
      class Genres < Grape::API
        version 'v5', using: :path
        format :json

        include RequestAuth

        resources :genres do
          desc "Return all the genres"
          get '/index', rabl: 'v5/genres/index' do
            @genres = Genre.top_genres.order(:name)
          end

          desc "list of all the user genres"
          get '/user_genres', rabl: 'v5/genres/index' do
            @genres = current_user.genres
          end

          desc "save genres against user"
          params do
            requires :genre_ids, type: Array[Integer], desc: 'list of database genre ids'
          end
          post '/user_genres', rabl: 'v5/genres/index' do
            @genres = current_user.create_user_genre!(params['genre_ids'])
          end

          desc "search genre by name"
          params do
            requires :keyword, type: String, desc: 'genre name e.g metal'
          end
          get '/search', rabl: 'v5/genres/index' do
            @genres = Genre.search(params[:keyword]).records
          end
        end
      end
    end
  end
end
