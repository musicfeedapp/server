# -*- coding: utf-8 -*-
# encoding: UTF-8

require 'json'

require 'aggregator'
Aggregator::Boot.setup

module Plugins
  class StorageWorker
    def perform(attributes)
      # here we searching by existing records and creating the activities for
      # publishers.
      AggregatorPublisher.publish(attributes)
    end
  end
end

require 'aggregator'
Aggregator.register_plugin(:storage, Plugins::StorageWorker)
