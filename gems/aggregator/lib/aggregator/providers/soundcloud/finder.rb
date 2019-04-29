# -*- coding: utf-8 -*-
# encoding: UTF-8

module Aggregator
  module Providers
    module Soundcloud

      class Finder
        APP_NAME = 'SoundCloud'

        def self.id(attributes)
          attributes['id']
        end

        def self.find(attributes, custom_attributes)
          facebook_attributes = Aggregator::Providers::Facebook::Attributes.new(attributes)
          return unless facebook_attributes.valid?

          app_attributes = Aggregator::Providers::Soundcloud::Attributes.new(custom_attributes)

          unless app_attributes.valid?
            LOGGER.debug("[SoundCloud::Finder] invalid attributes: #{attributes.inspect}")
          end
          return unless app_attributes.valid?

          builder = Aggregator::Models::TimelineBuilder.new(facebook_attributes, app_attributes)
          builder.build_for(:soundcloud)
        end

        def self.is?(attributes)
          (
           !attributes['application'].nil? &&
             attributes['application']['name'] == APP_NAME
          ) || attributes['link'].to_s.include?('soundcloud.com')
        end
      end

    end
  end
end
