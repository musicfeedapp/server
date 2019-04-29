# -*- coding: utf-8 -*-
# encoding: UTF-8

require 'sidekiq'
require 'json'

module Aggregator
  module Workers

    class BaseWorker
      include Sidekiq::Worker

      sidekiq_options queue: :timelines, retry: 10

      def perform(auth_token, facebook_id, who, options = {})
        LOGGER.debug("[BaseWorker] calling with facebook_id: #{facebook_id}")
        runner = Runner.new(auth_token, facebook_id, who, options)
        runner.do
      rescue => boom
        Notification.notify(boom, from: 'Worker', facebook_id: facebook_id, who: who)
        raise boom
      end

      class Runner
        include Aggregator::Providers::Facebook::Connection

        def initialize(auth_token, facebook_id, who, options)
          @auth_token = auth_token
          @facebook_id = facebook_id
          @who = who
          @options = options
        end

        attr_reader :auth_token, :facebook_id, :who, :options

        def do
          if who == 'me'
            collector_for(FEED_QUERY)
          else
            # in case we should get posts for artists
            collector_for(POSTS_QUERY)
          end
        end

        # On running collector_for we are enqueing nodes with facebook feeds
        # splitted by groups for faster analyzing.
        def enqueue(collection)
          begin
            collection.each_slice(10).map do |c|
              error = c.detect { |a| client_error?(a) }
              raise FacebookClientError.new(error) if error

              # Settings.debug

              id = Aggregator.client.set(c)

              Aggregator::Workers::NodeWorker.perform_async(auth_token, facebook_id, id)
            end
          rescue => boom
            Notification.notify(boom, from: 'Worker', facebook_id: facebook_id)
            raise FacebookClientError.new(boom.message)
          end
        end

        private

        def client_error?(attributes)
          attributes.is_a?(Koala::Facebook::ClientError)
        end
      end

    end
  end
end
