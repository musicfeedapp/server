# -*- coding: utf-8 -*-
# encoding: UTF-8

require 'json'

module Notification
  extend self

  def notify(boom, options = {})
    if boom.kind_of?(Exception)
      options.merge!(backtrace: boom.backtrace)
      message = boom.message
    else
      message = boom
    end

    LOGGER.error("[Error]: #{message}, options: #{options.inspect}")

    # Airbrake.notify(StandardError.new(message), parameters: options)
  end

  def error(boom, options = {})
    notify(boom, options)
  end
end
