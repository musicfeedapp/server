# -*- coding: utf-8 -*-
# encoding: UTF-8

module Aggregator
  module Providers
    module Spotify

      module Link
        module_function

        PATTERNS = [
          /open\.spotify\.com\/track\/(.+)$/,
          /spotify\:track\:(.+)$/,
        ]

        def id(link)
          ids = PATTERNS.map do |pattern|
            link =~ pattern
            $1
          end
          ids.compact.first
        end

        def uri(link)
          track_id = id(link)
          return if track_id.nil?
          "spotify:track:#{track_id}"
        end
      end

    end
  end
end
