# -*- coding: utf-8 -*-
# encoding: UTF-8

RedisConnection = -> {
  uri = URI.parse(Settings.redis.url)

  Redis.new(
    :host        => uri.host,
    :port        => uri.port,
    :password    => uri.password,
    :thread_safe => true,
  )
}

Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(size: 40, &RedisConnection)
end

Sidekiq.configure_server do |config|
  config.redis = ConnectionPool.new(size: 200, &RedisConnection)

  config.error_handlers << ->(boom, context) { Notification.error(boom, context: context) }

  if Settings.env == 'production'
    config.logger = nil
  end
end
