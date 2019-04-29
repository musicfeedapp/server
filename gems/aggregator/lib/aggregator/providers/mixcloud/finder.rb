# -*- coding: utf-8 -*-
# encoding: UTF-8

module Aggregator
  module Providers
    module Mixcloud

      class Finder
        APP_NAME = 'Mixcloud'

        def self.id(attributes)
          attributes['id']
        end

        def self.find(attributes, custom_attributes)
          facebook_attributes = Aggregator::Providers::Facebook::Attributes.new(attributes)
          return unless facebook_attributes.valid?

          app_attributes = Aggregator::Providers::Mixcloud::Attributes.new(custom_attributes)

          unless app_attributes.valid?
            LOGGER.debug("[Mixcloud::Finder] invalid attributes: #{attributes.inspect}")
          end
          return unless app_attributes.valid?

          builder = Aggregator::Models::TimelineBuilder.new(facebook_attributes, app_attributes)
          builder.build_for(:mixcloud)
        end

        def self.is?(attributes)
          (
           !attributes['application'].nil? &&
             attributes['application']['name'] == APP_NAME
          ) || attributes['link'].to_s.include?('mixcloud.com')
        end
      end

    end
  end
end
