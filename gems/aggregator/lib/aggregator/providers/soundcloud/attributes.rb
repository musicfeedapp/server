# -*- coding: utf-8 -*-
# encoding: UTF-8

require 'soundcloud'

module Aggregator
  module Providers
    module Soundcloud

      Api = Struct.new(:soundcloud_id) do
        include Aggregator::Search::SoundcloudSearch

        def artist
          track.artist
        end

        def name
          track.name
        end

        def picture
          track.picture
        end

        def link
          track.link
        end

        def valid?
          track.valid? && !link.nil?
        end
      end

      Attributes = Struct.new(:attributes) do
        def api
          @api ||= Aggregator::Providers::Soundcloud::Api.new(attributes['link'])
        end

        def name
          api.name
        end

        def link
          api.link || attributes['link']
        end

        def description
          attributes['description']
        end

        def music
          @music ||= Aggregator::Providers::Soundcloud::Music.new(link)
        end

        def valid?
          api.valid? && !name.nil? && !link.nil? && !link.include?("/sets/")
        end

        def message
          attributes['message'] || attributes['description']
        end

        def picture
          api.picture || attributes['picture']
        end

        def artist
          api.artist
        end

        def assign_to(t)
          t.link         = link
          t.source_link  = link
          t.message      = message
          t.picture      = picture
          t.artist       = artist
        end

        include Aggregator::Search::YoutubeSearch
      end

    end
  end
end
