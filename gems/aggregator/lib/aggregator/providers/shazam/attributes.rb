# -*- coding: utf-8 -*-
# encoding: UTF-8

module Aggregator
  module Providers
    module Shazam

      Attributes = Struct.new(:attributes) do
        def music
          @music ||= Aggregator::Providers::Shazam::Music.new(name)
        end

        def id
          attributes['id']
        end

        def name
          attributes['name']
        end

        def link
          attributes['link']
        end

        def description
          attributes['description']
        end

        def message
          attributes['message']
        end

        def picture
          @picture ||= "https://img.youtube.com/vi/#{youtube_id}/hqdefault.jpg"
        end

        def valid?
          !name.nil? && !link.nil? && !youtube_link.nil? && music?
        end


        def music?
          category.include?('music')
        end

        def category
          @category ||= categories(id)
        end

        def assign_to(t)
          t.link         = link
          t.source_link  = link
          t.youtube_id   = youtube_id
          t.youtube_link = youtube_link
          t.message      = message
          t.album        = music.album
          t.artist       = music.artist
          t.picture      = picture
          t.name         = name
          t.category     = category
        end

        include Aggregator::Search::YoutubeSearch
      end

      class Music
        attr_reader :album, :artist

        def initialize(name)
          @artist, @album = name.split(/-/)
          @artist = @artist.to_s.strip
          @album  = @album.to_s.strip
        end
      end

    end
  end
end
