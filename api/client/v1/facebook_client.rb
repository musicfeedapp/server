require 'aggregator'

# because of using proposals and facebook subscriptions here lets skip
# lazy loading.
require 'social'

module Api
  module Client
    module V1

      VERIFY_TOKEN = 'specific-token-111'
      # TODO: replace it by Rails.configuration.host because of using staging,
      # production environments later.
      CALLBACK_URL = 'http://musicfeed.rubyforce.co/api/client/facebook/subscriptions'

      class FacebookClient < Grape::API
        # We should use text format for accepting facebook json requests.
        format :txt

        namespace :facebook do
          namespace :subscriptions do
            get '/' do
              Koala::Facebook::RealtimeUpdates.meet_challenge(params) do |token|
                token == VERIFY_TOKEN
              end
            end

            post '/' do
              subscriptions = Facebook::Subscriptions.new

              if subscriptions.client.validate_update(request.body.read.to_s, request.headers)
                Facebook::SubscriberWorker.perform_async(params)
              end
            end
          end
        end
      end
    end
  end
end
