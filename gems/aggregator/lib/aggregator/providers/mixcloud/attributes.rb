# -*- coding: utf-8 -*-
# encoding: UTF-8

module Aggregator
  module Providers
    module Mixcloud

      Attributes = Struct.new(:attributes) do
        def description
          attributes['description']
        end

        def name
          attributes['name']
        end

        def description
          attributes['description']
        end

        def link
          attributes['link']
        end

        def api
          @api ||= Aggregator::Providers::Mixcloud::Api.new(link)
        end

        def valid?
          !name.nil? && !link.nil? && !api.url.nil?
        end

        def assign_to(t)
          t.link         = link
          t.source_link  = link
          t.picture      = picture
          t.message      = attributes['message'] || attributes['description']
          t.artist       = api.artist
          t.name         = name
          t.stream       = stream
        end

        def stream
          api.url
        end

        def picture
          api.picture || attributes['picture']
        end

        include Aggregator::Search::YoutubeSearch
      end

      # example of extractor for mixcloud
      # https://github.com/rg3/youtube-dl/blob/master/youtube_dl/extractor/mixcloud.py
      Api = Struct.new(:link) do
        def attributes
          @attributes ||= if content.nil? || content == ""
                            {}
                          else
                            content =~ /m\-preview\=\"((.+)\.mp3)\"/
                            url = $1

                            url = url.to_s.gsub(/audiocdn(\d+)/, 'stream\1')

                            unless url.nil?
                              url = url.to_s.gsub('/previews/', '/c/originals/')
                              unless verify(url)

                                url = url.to_s.gsub('.mp3', '.m4a').gsub('originals/', 'm4a/64/')
                                unless verify(url)
                                  url = nil # we could get url for mixcloud properly.
                                end
                              end
                            end

                            content =~ /m\-thumbnail\-url\=\"([^"]+)\"/
                            picture = $1

                            content =~ /m\-owner\-name\=\"([^"]+)\"/
                            uploader = $1

                            { url: url, picture: picture, uploader: uploader }
                          end
        end

        def artist
          attributes[:uploader].force_encoding("UTF-8")
        end

        def url
          attributes[:url]
        end

        def picture
          attributes[:picture].to_s.gsub('/w/60/h/60/', '/w/400/h/400/')
        end

        private

        def content
          @content ||= begin
                         response = Faraday.get(link)
                         response.body
                       end
        end

        OK = 200
        def verify(url)
          response = Faraday.head(url)
          response.status == OK
        end
      end

    end
  end
end
