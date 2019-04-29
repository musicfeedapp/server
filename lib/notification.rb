module Notification
  extend self

  def notify(boom, options = {})
    if boom.kind_of?(Exception)
      options.merge!(backtrace: boom.backtrace)
      message = boom.message
    else
      message = boom
    end

    # Airbrake.notify(StandardError.new(message), parameters: options)
  end

  def error(boom, options = {})
    notify(boom, options)
  end
end
