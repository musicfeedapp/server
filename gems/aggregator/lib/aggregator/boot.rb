module Aggregator
  module Boot

    def setup
      # In some environments like test we could work despite on connection
      # to redis or couchdb.
      if Aggregator.redis.connected?
        Aggregator::FacebookApplicationQueue.clear
      end
    end
    module_function :setup

  end
end
