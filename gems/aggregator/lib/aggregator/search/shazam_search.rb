require 'nokogiri'

module Aggregator
  module Search

    module ShazamSearch
      Attributes = Struct.new(:attributes) do
        def title
          @name ||= begin
                      value = nil

                      attributes.css('.trd-title.js-dotdotdot').each do |header|
                        value = header.content.to_s.strip
                        break
                      end

                      value
                    end
        end

        # we should have name defined here for using youtube search.
        def name
          @name ||= "#{artist} - #{title}"
        end

        def link
          video.player_url
        end

        def picture
          @picture ||= begin
                         value = nil

                         attributes.css('.tr-cover-art img').each do |picture|
                           value = picture.attributes['src'].to_s
                           break
                         end

                         value
                       end
        end

        def artist
          @artist ||= begin
                         value = nil

                         attributes.css('.trd-artist.js-dotdotdot span a').each do |artist|
                           value = artist.content.to_s.strip
                           break
                         end

                         value
                       end
        end

        def valid?
          !artist.nil? && artist != '' && !title.nil? && title != ''
        end
      end

      def track
        @attributes ||= Attributes.new(
          begin
            response = Faraday.get(shazam_id)

            if response.status != 200
              # nothing to parse here, but lets use mock as empty string.
              Nokogiri::HTML("")
            else
              Nokogiri::HTML(response.body)
            end
          rescue
            Aggregator::Nullable::Connection.new
          end
        )
      end
    end
  end
end
