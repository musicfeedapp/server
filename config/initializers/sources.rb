# -*- coding: utf-8 -*-
# encoding: UTF-8

require 'json'

module Plugins

  class SourcesWorker

    # @param timeline_id - our id in the database
    # @param collection_attributes - item of collection should have at least
    # one attribute link to attach as one more source to timeline.
    def perform(timeline_id, collection_attributes)
      attributes.deep_stringify_keys!

      # TODO: here we should attach the sources collection to timeline.
    end
  end

end

require 'aggregator'
Aggregator.register_plugin(:sources, Plugins::SourcesWorker)
