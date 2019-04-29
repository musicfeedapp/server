# -*- coding: utf-8 -*-
# encoding: UTF-8

require 'json'

module Aggregator
  Appender = Struct.new(:facebook_id) do
    def append!(timelines)
      timelines.each do |timeline|
        # We should place timeline as json to redis and allow to use other background
        # processing for storing to database.
        id = Aggregator.client.set(timeline.to_h)
        Aggregator::Workers::StorageWorker.perform_async(id)
      end

      true
    end
  end
end
