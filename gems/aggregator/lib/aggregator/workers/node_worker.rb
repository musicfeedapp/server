# -*- coding: utf-8 -*-
# encoding: UTF-8

require 'koala'
require 'sidekiq'

module Aggregator
  module Workers
    # Class is working as node as entry params we are passing few items from Facebook and
    # depends on the their attributes we are creating timelines records and attaching the author
    # of the post and searching for an artist in our database for assigning
    # - artist_identifier
    # - user_identifier
    class NodeWorker
      include Sidekiq::Worker

      sidekiq_options queue: :timelines, retry: 10

      def perform(auth_token, facebook_id, id)
        LOGGER.debug "[NodeWorker] processing this attributes for #{facebook_id}"

        begin
          LOGGER.info("Begin running couch get for #{id}")
          c = Aggregator.client.get(id)
          LOGGER.info("Stop running couch get for #{id}")

          runner = Runner.new(auth_token, facebook_id, c)
          runner.do
        rescue => boom
          Notification.notify(boom, facebook_id: facebook_id)
          # dont raise anything
        ensure
          LOGGER.info("Begin running couch del for #{id}")
          Aggregator.client.del(id)
          LOGGER.info("Stop running couch del for #{id}")
        end
      end

      # Class is wrapping the search of feed_type and creating the records of timelines.
      class Runner
        include Aggregator::Providers::Facebook::Connection

        def initialize(auth_token, facebook_id, facebook_collections)
          @auth_token = auth_token
          @facebook_id = facebook_id
          @facebook_collections = facebook_collections
        end

        attr_reader :auth_token, :facebook_id, :facebook_collections

        def do
          facebook_collections.each do |attributes|
            next if attributes.nil? || attributes.size == 0

            attributes.deep_stringify_keys!

            if timeline = find(:youtube, facebook_attributes: attributes, custom_finder: true)
              storage.append!([timeline])
              next
            end

            if timeline = find(:soundcloud, facebook_attributes: attributes, custom_finder: true)
              storage.append!([timeline])
              next
            end

            if timeline = find(:shazam, facebook_attributes: attributes, custom_finder: true)
              storage.append!([timeline])
              next
            end

            if timeline = find(:mixcloud, facebook_attributes: attributes, custom_finder: true)
              storage.append!([timeline])
              next
            end

            if timeline = find(:spotify, facebook_attributes: attributes, custom_finder: true)
              storage.append!([timeline])
              next
            end
          end

          # Settings.debug

          # In case if we need to run extra queries for getting more details from
          # facebook about the specific posts like spotify
          finder_ids.each do |klass, ids|
            next if ids.nil? || client_error?(ids) || ids.size == 0

            begin
              objects_attributes = objects_for(ids.keys).flatten

              objects_attributes.each do |attributes|
                next if attributes.nil? || client_error?(attributes) || attributes.size == 0

                # Settings.debug

                begin
                  facebook_attributes = finder_ids[klass][attributes['id']]

                  begin
                    if timeline = find(:spotify  , facebook_attributes: facebook_attributes, custom_attributes:  attributes)
                      storage.append!([timeline])
                      next
                    end
                  rescue => boom
                    Notification.notify(boom, from: 'Worker', facebook_attributes: facebook_attributes, custom_attributes: attributes)
                  end

                  begin
                    if timeline = find(:mixcloud , facebook_attributes: facebook_attributes, custom_attributes:  attributes)
                      storage.append!([timeline])
                      next
                    end
                  rescue => boom
                    Notification.notify(boom, from: 'Worker', facebook_attributes: facebook_attributes, custom_attributes: attributes)
                  end

                  begin
                    if timeline = find(:shazam , facebook_attributes: facebook_attributes, custom_attributes:  attributes)
                      storage.append!([timeline])
                      next
                    end
                  rescue => boom
                    Notification.notify(boom, from: 'Worker', facebook_attributes: facebook_attributes, custom_attributes: attributes)
                  end

                  begin
                    if timeline = find(:soundcloud , facebook_attributes: facebook_attributes, custom_attributes: attributes)
                      storage.append!([timeline])
                      next
                    end
                  rescue => boom
                    Notification.notify(boom, from: 'Worker', facebook_attributes: facebook_attributes, custom_attributes: attributes)
                  end

                  begin
                    if timeline = find(:youtube , facebook_attributes: facebook_attributes, custom_attributes: attributes)
                      storage.append!([timeline])
                      next
                    end
                  rescue => boom
                    Notification.notify(boom, from: 'Worker', facebook_attributes: facebook_attributes, custom_attributes: attributes)
                  end
                rescue => boom
                  Notification.notify(boom, from: 'Worker', facebook_attributes: facebook_attributes, custom_attributes: attributes)
                end

              end
            rescue => boom
              Notification.notify(boom, from: 'Retryable::CustomFinder')
            end
          end # finder_ids.each
        end

        def finder_ids
          @finder_ids ||= Hash.new { |h, k| h[k] = {} }
        end

        ProvidersSettings = {
          youtube: {
            klass:  Aggregator::Providers::Youtube::Finder,
            finder: lambda { |options| Aggregator::Providers::Youtube::Finder.find(options[:facebook_attributes], options[:custom_attributes]) }
          },
          soundcloud: {
            klass:  Aggregator::Providers::Soundcloud::Finder,
            finder: lambda { |options| Aggregator::Providers::Soundcloud::Finder.find(options[:facebook_attributes], options[:custom_attributes]) }
          },
          shazam: {
            klass:  Aggregator::Providers::Shazam::Finder,
            finder: lambda { |options| Aggregator::Providers::Shazam::Finder.find(options[:facebook_attributes], options[:custom_attributes]) }
          },
          spotify: {
            klass:  Aggregator::Providers::Spotify::Finder,
            finder: lambda { |options| Aggregator::Providers::Spotify::Finder.find(options[:facebook_attributes], options[:custom_attributes]) }
          },
          mixcloud: {
            klass:  Aggregator::Providers::Mixcloud::Finder,
            finder: lambda { |options| Aggregator::Providers::Mixcloud::Finder.find(options[:facebook_attributes], options[:custom_attributes]) },
          },
        }

        def find(klass, options = {})
          timeline = nil

          settings = ProvidersSettings[klass]
          klass    = settings[:klass]
          method   = settings[:finder]

          facebook_attributes = options[:facebook_attributes]

          # @note it should be enabled in case of using spotify finder only for now
          # because of quite weird approace for getting spotify attributes.
          custom_finder_enabled = options.fetch(:custom_finder, false) && facebook_attributes['link'].nil?
          begin
            if klass.is?(facebook_attributes)
              begin
                if custom_finder_enabled
                  finder_ids[klass][klass.id(facebook_attributes)] = facebook_attributes
                end
              rescue => boom
                Notification.notify(boom, from: 'Worker', facebook_attributes: facebook_attributes, klass: klass, method: method)
              end

              # if we want to skip fore spotify finder for timeline.
              return if custom_finder_enabled

              # Settings.debug

              # in case if we don't have enough information in facebook
              # attributes, lets use story tags instead for getting more
              # information about spotify track.
              #
              # TODO: we should refactor it to use batch API instead of
              # separate calls.
              if facebook_attributes['link'].nil? && Aggregator::Providers::Spotify::Finder.is?(facebook_attributes)
                return if facebook_attributes['story_tags'].nil?

                tag = -> {
                  tag = facebook_attributes['story_tags'].values.flatten.find { |t| t['type'].nil? }
                  return if tag.nil?
                  facebook.get_object(tag['id'])
                }.call

                return if tag.nil?

                facebook_attributes['link'] = tag['url']
                facebook_attributes['name'] = tag['title']
                facebook_attributes['description'] = tag['description']
                facebook_attributes['stream'] = (tag.fetch('audio', []).first || {})['url']
                facebook_attributes['artist'] = (tag.fetch('data', {}).fetch('musician', []).first || {})['name']
              end

              method_attributes = {}
              method_attributes.merge!(options)
              method_attributes.merge!(facebook_attributes: facebook_attributes)

              unless custom_finder_enabled
                method_attributes.merge!(custom_attributes: facebook_attributes)
              end

              # now we can use storage.append!([timeline])
              timeline = method.call(method_attributes)
            end
          rescue => boom
            Notification.notify(boom, from: 'Worker', facebook_attributes: facebook_attributes, options: options)
          end

          timeline
        end

        private

        def storage
          @storage ||= Aggregator::Appender.new(facebook_id)
        end

        def client_error?(attributes)
          attributes.is_a?(Koala::Facebook::ClientError)
        end
      end
    end
  end
end
