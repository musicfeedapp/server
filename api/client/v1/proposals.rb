require 'koala'

class Api::Client::V1::Proposals < Grape::API
  format :json

  include RequestAuth

  SuccessResponse = [200, {}, '']

  resources :proposals do
    helpers do
      def enabled_ids
        @enabled_ids ||= Array(params[:facebook_id]).select { |facebook_id| boolean(facebook_id['followed']) }.map { |facebook_id| facebook_id['facebook_id'] }
      end

      def disabled_ids
        @disabled_ids ||= Array(params[:facebook_id]).select { |facebook_id| !boolean(facebook_id['followed']) }.map { |facebook_id| facebook_id['facebook_id'] }
      end

      def boolean(value)
        value == 'true'
      end
    end
    params do
      requires :facebook_id, type: Array, desc: 'ids of the friends or music pages Example: [{ facebook_id: 1, followed: true }]'
    end
    put '/' do
      User.transaction do
        # TODO: we are doing follow / unfollow stuff here only for one person/
        # request action.
        if enabled_ids.present?
          enabled_ids.each do |id|
            friend = User.find_by_facebook_id(id.to_s)
            current_user.follow!(friend)

            PushNotifications::Worker.perform_async(:follow, [current_user.id, friend.id])
          end
        end

        if disabled_ids.present?
          disabled_ids.each do |facebook_id|
            friend = User.find_by_facebook_id(facebook_id.to_s)
            current_user.unfollow!(friend)
          end
        end
      end

      SuccessResponse
    end
  end
end
