module Api
  module Client
    module V5
      class Users < Grape::API
        version 'v5', using: :path
        format :json

        include RequestAuth

        SuccessResponse = {}

        resources :users do
          desc "Get all friends of signed in"
          params do
            optional :auto_follow, type: Boolean, default: true
          end
          get '/friends', rabl: 'v1/users/friends' do
            @friends = current_user.friends
          end


          # TODO: implement it!
          desc "Get all remaining, new friends"
          params do
            optional :auto_follow, type: Boolean, default: true
          end
          get "/new_friends", rabl: 'v1/users/friends' do
            @friends = current_user.friends
          end

          desc "Update user profile"
          params do
            group :user, type: Hash do
              optional :username,         type: String
              optional :contact_number,   type: String
              optional :name,             type: String
              optional :email,            type: String
              optional :secondary_emails, type: Array[String]
              optional :secondary_phones, type: Array[String]
              optional :avatar,           type: Rack::Multipart::UploadedFile
              optional :remove_avatar,    type: Boolean
            end
          end

          put '/update_profile', rabl: "v1/users/update" do
            @user = current_user

            permited_params = declared(params, include_missing: false)['user']

            if permited_params[:avatar].present?
              permited_params[:avatar] = permited_params[:avatar][:tempfile]
            end

            unless @user.update_attributes(permited_params)
              throw :error, status: 400, message: ErrorSerializer.serialize(@user.errors)
            end
          end

          params do
            optional :auth_token, type: String
            optional :expires_at, type: DateTime
          end
          put '/update_token' do
            authentication = current_user.authentications.find_by_provider('facebook')

            throw :error, status: 404, message: ErrorSerializer.serialize(not_found_authentication: 'no facebook authentication') if authentication.blank?

            unless authentication.update_attributes(
              expires_at: params[:expires_at],
              auth_token: params[:auth_token])

              throw :error, status: 400, message: ErrorSerializer.serialize(authentication.errors)
            end

            SuccessResponse
          end

          params do
            requires :user_ext_id, type: String
          end
          put '/restrict_suggestion' do
            user = User.find_by_ext_id(params[:user_ext_id])

            unless user.present?
              throw :error, status: 404, message: ErrorSerializer.serialize(not_found: 'user with this ext id doesnot exists')
            end

            current_user.restricted_suggestions.merge!(Array(user.id.to_s))
            current_user.restricted_suggestions_will_change!
            current_user.save!

            SuccessResponse
          end
        end
      end
    end
  end
end
