require 'user_adapter'

module Api
  module Client
    module V3

      class Profile < Grape::API
        version 'v3', using: :path

        format :json

        include RequestAuth

        resource :profile do
          get '/', rabl: 'v3/profile/current_user' do
            @user = UserAdataper.new(current_user, current_user)
          end

          params do
            requires :username, type: String, desc: 'Unique token instead of username'
          end
          get '/show', rabl: 'v3/profile/show' do
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

          params do
            requires :username, type: String, desc: 'Unique token instead of username'
          end

          get '/followers', rabl: 'v3/profile/followed' do
            @user = User.where("users.username = ? OR users.ext_id = ?", params[:username], params[:username]).first
            @user = UserAdataper.new(current_user, @user)

            unless @user
              throw :error, status: 404, message: ErrorSerializer.serialize(not_found_user: "Not found user or artist by @<#{params[:username]}>")
            end
          end

          params do
            requires :username, type: String, desc: 'Unique token instead of username'
          end
          get '/following', rabl: 'v3/profile/following' do
            @user = User.where("users.username = ? OR users.ext_id = ?", params[:username], params[:username]).first
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
            optional :facebook_image, type: Boolean, desc: "If email user wanted to set facebook image and not connected with facebook previously"
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

                begin
                  @user, options = User.find_or_create_by_facebook_auth_token(facebook_attributes[:auth_token], { email: current_user.email, remove_avatar: params[:facebook_image] })

                  unless @user.present?
                    throw :error, status: 403, message: ErrorSerializer.serialize(invalid_auth_token: 'Invalid facebook auth token')
                  end

                  # As we have assign ext_id to facebook_id for email signedup users
                  # now after update we should also update the user_identifier for the the timelines

                  Timeline.transaction do
                    Timeline
                      .where(user_identifier: current_user.ext_id)
                      .update_all(user_identifier: @user.facebook_id)

                    TimelinePublisher
                      .where(user_identifier: current_user.ext_id)
                      .update_all(user_identifier: @user.facebook_id)
                  end

                  options ||= {}

                  RegistrationSteps.each do |step|
                    step.call(@user, options)
                  end
                rescue => boom
                  Notification.notify(boom, { from: "Api::Client::V1::Users" }.merge(params))
                  throw :error, status: 400, message: ErrorSerializer.serialize(bad_request: boom.message)
                end
              end
            end

            [200, { message: "User connected with facebook successfully." }, {}]
          end
        end
      end

    end
  end
end
