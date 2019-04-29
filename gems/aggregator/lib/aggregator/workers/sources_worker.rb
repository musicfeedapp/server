# -*- coding: utf-8 -*-
# encoding: UTF-8

module Aggregator
  module Workers

    class SourcesWorker
      include Sidekiq::Worker

      sidekiq_options queue: :timelines, retry: false

      SOURCES = [
        Aggregator::Recognize::Youtube,
        Aggregator::Recognize::Spotify,
        Aggregator::Recognize::Itunes,
      ]

      # @param timeline {Timeline}
      # @param attributes {Hash}:
      # - artist
      # - track
      # - title
      # one of the field for searching in spotify or youtube api.
      def perform(timeline, attributes)
        attributes.stringify_keys!

        artist = attributes['artist']
        track = attributes['track']
        title = attributes['title']

        sources = []

        SOURCES.each do |klass|
          begin

            if !artist.nil? && !track.nil?
              instance = klass.new(artist, track)

              if instance.valid? rescue nil
                sources.push(instance.attributes)
              else
                instance = klass.new(title, "")

                if instance.valid? rescue nil
                  sources.push(instance.attributes)
                else
                  instance = klass.new("", title)

                  if instance.valid? rescue nil
                    sources.push(instance.attributes)
                  end
                end # if
              end # if
            else
              instance = klass.new(title, "")

              if instance.valid? rescue nil
                sources.push(instance.attributes)
              else
                instance = klass.new("", title)

                if instance.valid? rescue nil
                  sources.push(instance.attributes)
                end
              end # if
            end # if
          rescue => boom
            LOGGER.debug("[SourcesWorker] something weng wrong for #{attributes.inspect} : #{boom.message}")
          end
        end

        Aggregator.plugins(:sources).each do |plugin_klass|
          LOGGER.debug("[SourcesWorker] calling plugin: #{plugin_klass.inspect} with #{timeline.inspect} and #{attributes.inspect}")

          instance = plugin_klass.new
          instance.perform(timeline)
        end
      end
    end

  end
end
