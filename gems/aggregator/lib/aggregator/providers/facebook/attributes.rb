# -*- coding: utf-8 -*-
# encoding: UTF-8

module Aggregator
  module Providers
    module Facebook

      Attributes = Struct.new(:attributes) do
        def method_missing(method_name, *arguments)
          attributes[method_name.to_s]
        end

        def to
          ((attributes['to'] || {})['data'] || []).map { |a| a['id'] }
        end


        def valid?
          true
        end

        def author
          @author ||= Aggregator::Providers::Facebook::Author.new(attributes)
        end

        def likes_count
          attributes.fetch('likes', {}).fetch('summary', {})['total_count'].to_i
        end

        def assign_to(t)
          t.identifier        = id
          t.name              = name
          t.description       = description
          t.author            = author.name
          t.user_identifier   = author.id
          t.author_picture    = author.picture
          t.published_at      = created_time
          t.likes_count       = likes_count
          t.picture           = picture
          t.to                = to
        end
      end

      Author = Struct.new(:attributes) do
        def present?
          !attributes['from'].nil?
        end

        def id
          attributes['from']['id'].to_s
        end

        def name
          attributes['from']['name']
            .to_s
            .gsub(/[^а-яА-Яa-zA-Z0-9]/,"")
            .split(/ /)
            .join
        end

        IMAGE = "http://graph.facebook.com/%s/picture?type=normal"
        def picture
          IMAGE % id
        end
      end

    end
  end
end
