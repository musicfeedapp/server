# -*- coding: utf-8 -*-
# encoding: UTF-8

module Aggregator
  module Providers
    module Grooveshark

      Attributes = Struct.new(:attributes) do
        def music
          @music ||= Aggregator::Providers::Grooveshark::Music.new(attributes.name)
        end

        def id
          @id ||= Aggregator::Providers::Youtube::Link.id(link)
        end

        def name
          attributes['name']
        end

        def link
          attributes['link']
        end

        def music?
          categories.include?('music')
        end

        def valid?
          !name.nil? && !link.nil? && music?
        end

        def description
          attributes.description
        end

        def message
          attributes['message']
        end

        def assign_to(t)
          t.link          = link
          t.source_link   = link
          t.youtube_id    = youtube_id
          t.youtube_link  = youtube_link
          t.message       = message
          t.album         = music.album
          t.artist        = music.artist
          t.picture       = picture
          t.name          = name
        end

        def picture
          @picture ||= "https://img.youtube.com/vi/#{youtube_id}/hqdefault.jpg"
        end

        include Aggregator::Search::YoutubeSearch
      end

      class Music
        attr_reader :album, :artist

        def initialize(name)
          @name, rest = name.split(/\bby\b/).map(&:strip)
          @artist, album = rest.split(/\bon\b/).map(&:strip)
          @album  = album.to_s.strip
        end
      end

    end
  end
end
