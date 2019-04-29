module Api
  module Client
    module V4
      class Itunes < Grape::API
        version 'v4', using: :path
        format :json

        include RequestAuth

        resources :itunes do
          params do
            requires :artists, type: Array
          end
          get '/', rabl: 'v4/itunes/index' do
            @artists = current_user
              .multiple_artist_search(params[:artists])
              .with_is_followed(current_user)
          end
        end
      end
    end
  end
end
