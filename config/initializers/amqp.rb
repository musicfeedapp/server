require 'bunny'

class Publisher
  PAGES_QUEUE_NAME = "pages.aggregator"
  USERS_QUEUE_NAME = "users.aggregator"

  def self.publish(message = {}, queue = PAGES_QUEUE_NAME)
    arguments = {
      "x-dead-letter-exchange" => "",
      "x-dead-letter-routing-key" => "#{queue}.error"
    }

    c = channel(queue)
    x = c.fanout(queue)
    # declare queue for receiving errors
    q = c.queue("#{queue}.error", :durable => true)
    # declare queue for publishing messages
    q = c.queue(queue, :durable => true, :arguments => arguments).bind(x)
    q.publish(message.to_json)
  end

  def self.channel(q)
    @channels ||= {}
    @channels[q] ||= connection.create_channel
    @channels[q]
  end

  # We are using default settings here
  # The `Bunny.new(...)` is a place to
  # put any specific RabbitMQ settings
  # like host or port
  def self.connection
    @connection ||= Bunny.new(host).tap do |c|
      c.start
    end
  end

  def self.host
    return 'amqp://musicfeedserver_rabbitmq:5672' if development?
    "amqp://feedler:feedler@192.241.163.72:5672" # music-rabbit
  end

  def self.env
    env = Rails.env rescue nil
    return env if env
    ENV.fetch('RACK_ENV', 'production') || ENV.fetch('RAILS_ENV', 'production')
  end

  def self.development?
    env == 'development' || env == 'test'
  end

  def self.close
    connection.close
  end
end
