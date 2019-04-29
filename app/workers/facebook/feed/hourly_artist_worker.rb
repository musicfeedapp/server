# -*- coding: utf-8 -*-
require 'aggregator'

module Facebook
  module Feed

    class HourlyArtistWorker
      include Sidekiq::Worker

      BATCH_SIZE = 1000
      DEFAULT_SLEEP = 1.0

      sidekiq_options queue: :aggregator, retry: false, :unique => :until_executed

      # ws:ha:in - worker in progress
      # ws:ha:pg - pages number
      # ws:ha:tm - time when we run it

      def perform
        return if $redis.exists('ws:ha:in')

        $redis.del("ws:ha:pg")

        $redis.set('ws:ha:in', true)
        $redis.expire('ws:ha:in', 2.hours.to_i)

        $redis.set("ws:ha:tm", DateTime.now.to_s(:db))

        User.artist.
          where('lower(users.category) IN (?)', User::LIKE_TYPES).
          where('users.facebook_id IS NOT NULL').
          select('users.id, users.facebook_id').
          order('timelines_count DESC').
          limit(400000).
          find_in_batches(batch_size: BATCH_SIZE) do |users|
            requests_for(users)
            sleep DEFAULT_SLEEP
          end
      ensure
        $redis.del('ws:ha:in')
      end

      def requests_for(users)
        users = Array(users)

        # ws = workers
        # as = artists
        # pg = progress
        # ex = expected
        $redis.incrby("ws:ha:pg", users.size)

        users.map do |user|
          key = "ag:fb:#{user.facebook_id}:fs"

          if $redis.get(key) != "processing"
            $redis.set(key, "processing")
            $redis.expire(key, 5.days.to_i)

            Publisher.publish({access_token: Aggregator::FacebookApplicationQueue.next, object_id: user.facebook_id, who: user.facebook_id, options: {recent: true}})
          end
        end
      end
    end

  end
end
