require 'koala'

class Api::Client::V2::Proposals < Grape::API
  format :json

  include RequestAuth

  SuccessResponse = [200, {}, '']

  resources :proposals do
    helpers do
      def enabled_ids
        @enabled_ids ||= Array(params[:ext_ids]).select { |ext_id| boolean(ext_id['followed']) }.map { |ext_id| ext_id['ext_id'] }
      end

      def disabled_ids
        @disabled_ids ||= Array(params[:ext_ids]).select { |ext_id| !boolean(ext_id['followed']) }.map { |ext_id| ext_id['ext_id'] }
      end

      def boolean(value)
        value == 'true'
      end
    end
    params do
      requires :ext_ids, type: Array, desc: 'ids of the friends or music pages Example: [{ ext_id: 1, followed: true }]'
    end
    put '/' do
      User.transaction do
        # TODO: we are doing follow / unfollow stuff here only for one person/
        # request action.
        if enabled_ids.present?
          enabled_ids.each do |id|
            friend = User.find_by_ext_id(id.to_s)
            current_user.follow!(friend)

            PushNotifications::Worker.perform_async(:follow, [current_user.id, friend.id])
          end
        end

        if disabled_ids.present?
          disabled_ids.each do |ext_id|
            friend = User.find_by_ext_id(ext_id.to_s)
            current_user.unfollow!(friend)
          end
        end
      end

      SuccessResponse
    end
  end
end
