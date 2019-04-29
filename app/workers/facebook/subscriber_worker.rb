module Facebook

  class SubscriberWorker
    include Sidekiq::Worker

    # Facebook realtime updates is passing only ids for changed
    # object.
    #
    # For example uid: <facebook-user-id>, changed_fields:
    # ['feed', 'music']
    #
    # This request could come with multiple entries for the
    # different users.
    def perform(params)
      Rails.logger.debug("[FacebookClient.Worker] getting #{params}")

      params['entry'].each do |entry|
        user = User.find_by_facebook_id(entry['uid'])

        # sometimes we could have empty object because of having the
        # user inside of our facebook app but we don't have it in our
        # app database because of removals for testing purporse
        next if user.nil?
        next if !user.artist? && user.authentications.facebook.expired_for_today?

        Rails.logger.debug("[FacebookClient.Worker.Processing] searching user: #{params}")

        LOGGER.debug("[FacebookClient] begin #{user.email}, facebook_id: #{user.facebook_id}")

        if user.artist?
          auth_token = nil
          facebook_id = nil

          users = User.joins(:authentications).where('authentications.expires_at >= NOW()').all

          users.each do |u|
            client = u.authentications.facebook.client

            # Lets check user access to facebook api before to make requests.
            begin
              client.get_object('me')
            rescue
              next
            end

            auth_token = u.authentications.facebook.auth_token
            facebook_id = u.facebook_id

            next if auth_token.blank?
            break
          end
        else
          auth_token = user.authentications.facebook.auth_token
          facebook_id = user.facebook_id
        end

        LOGGER.debug("[FacebookClient] calling with #{user.email}, facebook_id: #{facebook_id}")

        Array(entry['changed_fields']).each do |field|
          case field
          when 'feed'
            Rails.logger.debug("[FacebookClient.Worker.Processing] updating user feed: #{params}")

            $redis.hset("fb:sb:#{user.facebook_id}", "feed_updated_time", DateTime.now.to_s(:db))

            if user.artist?
              Publisher.publish({access_token: auth_token, object_id: facebook_id, who: user.facebook_id, options: {recent: true}}, "users.aggregator")
            else
              Publisher.publish({access_token: auth_token, object_id: facebook_id, who: 'me', options: {recent: true}}, "users.aggregator")
            end
          when 'home'
            Rails.logger.debug("[FacebookClient.Worker.Processing] updating user home: #{params}")

            $redis.hset("fb:sb:#{user.facebook_id}", "feed_updated_time", DateTime.now.to_s(:db))

            Publisher.publish({access_token: auth_token, object_id: facebook_id, who: 'me', options: {recent: true}}, "users.aggregator")
          when 'music'
            Rails.logger.debug("[FacebookClient.Worker.Processing] updating user music: #{params}")

            $redis.hset("fb:sb:#{user.facebook_id}", "music_updated_time", DateTime.now.to_s(:db))

            maker = Facebook::Proposals::Maker.new(user)
            maker.find!
          end
        end
      end
    end
  end

end

