module Api
  module Client
    module V4

      class Unsigned < Grape::API
        version 'v4', using: :path

        format :json

        resource :unsigned do
          helpers do
            def user
              @user ||= User.find_or_initialize_by(device_id: params[:device_id])
            end
          end

          params do
            requires :device_id, type: String
            optional :last_timeline_id, type: Integer
          end
          get '/tracks', rabl: 'v4/unsigned/timelines' do
            service = UnSignedUserService.new(user, params)

            @timelines, @activities, @publishers = service.timelines
          end

          params do
            requires :device_id, type: String
            requires :phone_artists, type: Array[Hash], desc: 'Array of dictionaries containting name of artist that will come from client'
          end
          post '/user', rabl: 'v4/unsigned/unsigned_user' do
            unsigned_user = UnSignedUserService.new(user)
            @user = unsigned_user.create_unsigned_user!(params[:phone_artists])
          end
        end
      end

    end
  end
end
