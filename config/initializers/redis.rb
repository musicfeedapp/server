require 'redis-namespace'

redis_uri = URI.parse(Rails.configuration.redis.url)

redis_connection = Redis.new(:host => redis_uri.host,
                             :port => redis_uri.port,
                             :password => redis_uri.password,
                             :thread_safe => true)

if Rails.env.staging? || Rails.env.test?
  $redis = Redis::Namespace.new("rs-#{Rails.env}", :redis => redis_connection)
else
  $redis = redis_connection
end
