require 'aggregator'

module Facebook
  module Feed

    class UserWorker
      include Sidekiq::Worker

      sidekiq_options queue: :aggregator, retry: 2

      def perform(user_id, options)
        user = User.find(user_id)
        return if !user.artist? && user.authentications.facebook.expired_for_today?

        auth_token = user.authentications.facebook.auth_token
        facebook_id = user.facebook_id

        Publisher.publish({access_token: auth_token, object_id: facebook_id, who: 'me', options: options}, "users.aggregator")
      end
    end

  end
end
