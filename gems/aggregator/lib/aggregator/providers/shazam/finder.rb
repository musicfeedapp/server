# -*- coding: utf-8 -*-
# encoding: UTF-8

module Aggregator
  module Providers
    module Shazam

      class Finder
        APP_NAME = 'Shazam'

        def self.id(attributes)
          attributes['id']
        end

        def self.find(attributes, custom_attributes)
          facebook_attributes = Aggregator::Providers::Facebook::Attributes.new(attributes)
          return unless facebook_attributes.valid?

          app_attributes = Aggregator::Providers::Shazam::Attributes.new(custom_attributes)

          unless app_attributes.valid?
            LOGGER.debug("[Shazam::Finder] invalid attributes: #{attributes.inspect}")
          end
          return unless app_attributes.valid?

          builder = Aggregator::Models::TimelineBuilder.new(facebook_attributes, app_attributes)
          builder.build_for(:shazam)
        end

        def self.is?(attributes)
          (
           !attributes['application'].nil? &&
             attributes['application']['name'] == APP_NAME
          ) || attributes['link'].to_s.include?('shazam.com')
        end
      end

    end
  end
end
