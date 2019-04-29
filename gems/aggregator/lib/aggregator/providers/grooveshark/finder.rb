# -*- coding: utf-8 -*-
# encoding: UTF-8

module Aggregator
  module Providers
    module Grooveshark

      class Finder
        APP_NAME = 'Grooveshark'

        def self.id(attributes)
          attributes['id']
        end

        def self.find(attributes)
          facebook_attributes = Aggregator::Providers::Facebook::Attributes.new(attributes)
          return unless facebook_attributes.valid?

          app_attributes = Aggregator::Providers::Grooveshark::Attributes.new(facebook_attributes)
          return unless app_attributes.valid?

          builder = Aggregator::Models::TimelineBuilder.new(facebook_attributes, app_attributes)
          builder.build_for(:grooveshark)
        end

        def self.is?(attributes)
          (!attributes['application'].nil? &&
           attributes['application']['name'] == APP_NAME) ||
            (attributes['link'].to_s.include?('grooveshark.com'))
        end
      end

    end
  end
end
