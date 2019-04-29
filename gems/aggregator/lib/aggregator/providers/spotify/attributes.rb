# -*- coding: utf-8 -*-
# encoding: UTF-8

require 'json'

module Aggregator
  module Providers
    module Spotify
      Api = Struct.new(:spotify_id) do
        include Aggregator::Search::SpotifySearch

        def name
          track.name
        end

        def artist
          track.artist
        end

        def album
          track.album
        end

        def picture
          track.picture
        end

        def valid?
          !name.nil? && !artist.nil? && !album.nil?
        end
      end

      Attributes = Struct.new(:attributes) do
        def name
          attributes['name']
        end

        def picture
          api.picture || attributes['picture']
        end

        def spotify_id
          @spotify_id ||= Aggregator::Providers::Spotify::Link.id(link)
        end

        def api
          @api ||= Aggregator::Providers::Spotify::Api.new(spotify_id)
        end

        def link
          attributes['link']
        end

        def description
          attributes['description']
        end

        def message
          attributes['message'] || attributes['description']
        end

        def valid?
          !link.nil? && !spotify_id.nil? && api.valid?
        end

        def artist
          api.artist
        end

        # preview mp3
        def stream
          attributes['stream']
        end

        def assign_to(t)
          t.name         = name
          t.link         = link
          t.message      = message
          t.source_link  = link
          t.album        = api.album
          t.artist       = artist
          t.picture      = picture
          t.stream       = stream
        end
      end
    end
  end
end
