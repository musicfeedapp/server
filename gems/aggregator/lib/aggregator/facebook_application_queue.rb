module Aggregator

  module FacebookApplicationQueue
    extend self

    NAMESPACE = 'fb-queue'

    def next
      load unless exists?

      key = Aggregator.redis.lpop(NAMESPACE)
      Aggregator.redis.rpush(NAMESPACE, key)

      key
    end

    def exists?
      Aggregator.redis.exists(NAMESPACE)
    end

    def load
      Array(FacebookApplications.facebook.applications).each do |key|
        next if key.nil? || key.strip == ""
        Aggregator.redis.lpush(NAMESPACE, key)
      end
    end

    def clear
      Aggregator.redis.del(NAMESPACE)
    end
  end

end
