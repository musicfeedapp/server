require 'user_adapter'

class Api::Client::V1::Profile < Grape::API
  format :json

  include RequestAuth

  resource :profile do
    get '/', rabl: 'v1/profile/current_user' do
      @user = UserAdataper.new(current_user, current_user)
    end

    get '/:username', rabl: 'v1/profile/show' do
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
        .find_by_username(params[:username])
      @user = UserAdataper.new(current_user, @user)

      unless @user
        throw :error, status: 404, message: ErrorSerializer.serialize(not_found_user: "Not found user or artist by @<#{params[:username]}>")
      end
    end

    post '/refresh' do
      Facebook::Feed::UserWorker.perform_async(current_user.id, month: 1)
    end
  end
end
