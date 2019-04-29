# -*- coding: utf-8 -*-
# encoding: UTF-8

module Aggregator
  module Providers
    module Youtube

      module Link
        module_function

        PATTERNS = [
                    /%3D(.+)%26feature/i,
                    /\/v\/(.+)[&#].{0,}$/,
                    /v=(.+)[&#].{0,}$/,
                    /\/v\/(.+)$/,
                    /v=(.+)$/,
                    /youtu\.be\/(.+)[&#].{0,}$/,
                    /youtu\.be\/(.+)$/,
                   ]

        def id(link)
          ids = PATTERNS.map do |pattern|
            link =~ pattern
            $1
          end
          ids.compact.first
        end

        def normalize_link(link)
          youtube_id = id(link)
          return if youtube_id.nil?
          link(youtube_id)
        end

        def link(id)
          "http://www.youtube.com/v/#{id}"
        end
      end

    end
  end
end
