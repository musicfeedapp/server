require 'faraday'

module Facebook
  class Subscriptions
    VERIFY_TOKEN = 'specific-token-111'

    def client
      @client ||= Koala::Facebook::RealtimeUpdates.new(
        :app_id => Rails.configuration.facebook.id,
        :secret => Rails.configuration.facebook.secret,
      )
    end

    VERIFY_TOKEN = 'specific-token-111'
    CALLBACK_URL = 'https://musicfeed.rubyforce.co/api/client/facebook/subscriptions'

    def subscribe
      client.subscribe('user', 'friends, feed, music', CALLBACK_URL, VERIFY_TOKEN)
    end
  end
end
