# -*- coding: utf-8 -*-
# encoding: UTF-8


module Aggregator
  module Models

    TimelineBuilder = Struct.new(:facebook_attributes, :app_attributes) do
      def build_for(feed_type)
        timeline = Aggregator::Models::Timeline.new

        facebook_attributes.assign_to(timeline)
        app_attributes.assign_to(timeline)

        timeline.import_source = 'feed'
        timeline.feed_type = feed_type
        timeline.itunes_link = Aggregator::Search::ItunesSearch.search(timeline.artist, timeline.name)

        timeline
      end
    end

  end
end
