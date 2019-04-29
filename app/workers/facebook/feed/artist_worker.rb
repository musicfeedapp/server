# -*- coding: utf-8 -*-
require 'aggregator'

module Facebook
  module Feed

    class ArtistWorker
      include Sidekiq::Worker

      sidekiq_options queue: :aggregator, retry: false, :unique => :until_executed

      BATCH_SIZE = 2000
      DEFAULT_SLEEP = 0.1

      def perform(collection = nil)
        return if collection.is_a?(Array) && collection.empty?

        # if we don't run for specific artists we should wait the next run
        # for whole collection.
        unless collection.present?
          return if $redis.exists('ws:as:in')
        end

        $redis.del("ws:as:pg")

        $redis.set('ws:as:in', true)
        $redis.expire('ws:as:in', 23.hours.to_i)

        $redis.set("ws:as:tm", DateTime.now.to_s(:db))

        if collection.is_a?(Numeric)
          collection = [collection.to_i.to_s]
        end

        if collection.present?
          collection.each_slice(BATCH_SIZE) do |user_ids|
            requests_for(User.find(user_ids))
            sleep DEFAULT_SLEEP
          end
        else
          User.artist.select('users.id, users.facebook_id').where('lower(users.category) IN (?)', User::LIKE_TYPES).where('users.facebook_id IS NOT NULL').find_in_batches(batch_size: BATCH_SIZE) do |users|
            requests_for(users)
            sleep DEFAULT_SLEEP
          end
        end

      ensure
        $redis.del('ws:as:in')
      end

      def requests_for(users)
        users = Array(users)

        # ws = workers
        # as = artists
        # pg = progress
        # ex = expected
        $redis.incrby("ws:as:pg", users.size)

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
