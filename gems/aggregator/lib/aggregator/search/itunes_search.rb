# -*- coding: utf-8 -*-
# encoding: UTF-8

require 'uri'
require 'json'
require 'faraday'

module Aggregator
  module Search

    module ItunesSearch
      def search(artist, name)
        if !artist.nil? && artist != ''
          begin
            instance = Link.new(artist, name)
            instance.get
          end || begin
            instance = Link.new(artist)
            instance.get
          end || begin
            instance = Link.new(name)
            instance.get
          end
        else
          instance = Link.new(name)
          instance.get
        end
      end
      module_function :search
    end

    Link = Struct.new(:word1, :word2) do
      def get
        return if track.nil?
        "#{track}&at=#{Settings.affiliate_id}"
      end

      def track
        @track ||= begin
                     json = LinkExtractor.get(word1, word2)
                     (Array(json['results'])[0] || {})['trackViewUrl']
                   end
      end
    end

    module LinkExtractor
      extend self

      NO_LINK = { 'results' => [] }

      # @note we should pass country on each request to our application, probably
      # we should store or cache it somehow for later usage in the workers depends
      # on the client.
      DEFAULT_COUNTRY = 'us'

      def get(*words)
        words = words.compact.join(" ")
        uri = URI.parse("https://itunes.apple.com/search?&limit=1&entry=song&country=#{DEFAULT_COUNTRY}")
        uri.query += "&term=#{words}"

        begin
          response = Faraday.get(uri.to_s)
          JSON.parse(response.body)
        rescue => boom
          Notification.notify(boom, from: "ItunesAffilateLink")
          NO_LINK
        end
      end
    end

  end
end
