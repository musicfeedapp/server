# -*- coding: utf-8 -*-
# encoding: UTF-8

module Aggregator
  module Providers
    module Youtube

      Attributes = Struct.new(:attributes) do
        def music
          @music ||= Aggregator::Providers::Youtube::Music.new(attributes['name'])
        end

        def id
          @id ||= Link.id(link)
        end

        def link
          @link ||= begin
                      value = attributes['link'] || youtube_link
                      value = Link.normalize_link(value)
                      value
                    end
        end

        def name
          attributes['name']
        end

        def valid?
          !attributes['name'].nil? && !link.nil? && music?
        end

        def music?
          category.include?('music')
        end

        def category
          @category ||= categories(id)
        end

        def description
          attributes['description']
        end

        def picture
          "https://i.ytimg.com/vi/#{youtube_id}/hqdefault.jpg"
        end

        def message
          attributes['message']
        end

        def assign_to(t)
          t.name         = name
          t.link         = link
          t.source_link  = link
          t.youtube_id   = id
          t.youtube_link = link
          t.message      = message
          t.description  = description
          t.album        = music.album
          t.category     = category.first.to_s
          t.view_count   = view_count(id)

          # TODO: add here artist identifier
          t.artist       = artist
          t.picture      = picture
        end

        def artist
          music.artist
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
