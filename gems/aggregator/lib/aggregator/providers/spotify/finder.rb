# -*- coding: utf-8 -*-
# encoding: UTF-8

module Aggregator
  module Providers
    module Spotify

      class Finder
        APP_NAME = 'Spotify'

        def self.is?(attributes)
          is = !attributes['application'].nil? &&
            attributes['application']['name'] == APP_NAME

          if is && Settings.development?
            # Settings.debug
          end

          is
        end

        def self.id(attributes)
          attributes['id']
        end

        def self.find(facebook_attributes, custom_attributes)
          Settings.debug

          facebook_attributes = Aggregator::Providers::Facebook::Attributes.new(facebook_attributes)
          return unless facebook_attributes.valid?

          app_attributes = Aggregator::Providers::Spotify::Attributes.new(custom_attributes)
          return unless app_attributes.valid?

          builder = Aggregator::Models::TimelineBuilder.new(facebook_attributes, app_attributes)
          builder.build_for(:spotify)
        end
      end

    end
  end
end
