require 'user_adapter'

module Api
  module Client
    module V2

      class Profile < Grape::API
        version 'v2', using: :path

        format :json

        include RequestAuth

        resource :profile do
          get '/', rabl: 'v1/profile/current_user' do
            @user = UserAdataper.new(current_user, current_user)
          end

          params do
            requires :username, type: String, desc: 'Unique token instead of username'
          end
          get '/show', rabl: 'v1/profile/show' do
            @user = User
            .select(<<-SQL
              users.*,
              EXISTS(
                SELECT 1 FROM user_followers
                WHERE
                  user_followers.follower_id=#{current_user.id} AND
                  user_followers.followed_id=users.id AND
                  user_followers.is_followed=true
              ) AS is_followed
            SQL
            .squish)
            .where("users.username = ? OR users.ext_id = ?", params[:username], params[:username])
            .first
            @user = UserAdataper.new(current_user, @user)

            unless @user
              throw :error, status: 404, message: ErrorSerializer.serialize(not_found_user: "Not found user or artist by @<#{params[:username]}>")
            end
          end

          post '/refresh' do
            Facebook::Feed::UserWorker.perform_async(current_user.id, month: 1, home: true)
          end

          helpers do
            def facebook_attributes
              @facebook_attributes ||= params[:facebook]
            end

            def facebook_attributes?
              facebook_attributes.present?
            end
          end
          params do
            optional :facebook, type: Hash, desc: "should have { auth_token: 'token', uid: 'facebook user id' } on create, should have { destroy: 1 } on destroy"
          end
          put do
            if facebook_attributes?
              authentication = current_user.authentications.find_or_initialize_by(provider: 'facebook')

              if facebook_attributes[:destroy].present?
                authentication.persisted? && authentication.destroy!
              else
                authentication.email = current_user.email
                authentication.auth_token = facebook_attributes[:auth_token]
                authentication.uid = facebook_attributes[:uid]
                authentication.save!
              end
            end

            [200, {}, {}]
          end
        end
      end

    end
  end
end
