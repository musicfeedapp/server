require 'sidekiq'

RedisConnection = -> {
  uri = URI.parse(Rails.configuration.redis.url)

  $redis = Redis.new(
    :host        => uri.host,
    :port        => uri.port,
    :password    => uri.password,
    :thread_safe => true,
  )
}

if Rails.env.production?
  Sidekiq.configure_client do |config|
    config.redis = ConnectionPool.new(size: 50, &RedisConnection)
  end

  Sidekiq.configure_server do |config|
    config.redis = ConnectionPool.new(size: 200, &RedisConnection)

    config.error_handlers << ->(boom, context) { Notification.error(boom, context: context) }
  end
end

if Rails.env.staging?
  Sidekiq.configure_client do |config|
    config.redis = ConnectionPool.new(size: 10, &RedisConnection)
  end

  Sidekiq.configure_server do |config|
    config.redis = ConnectionPool.new(size: 20, &RedisConnection)

    config.error_handlers << ->(boom, context) { Notification.error(boom, context: context) }
  end
end
