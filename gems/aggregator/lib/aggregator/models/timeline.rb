# -*- coding: utf-8 -*-
# encoding: UTF-8

module Aggregator
  module Models

    # `to` is using for storing facebook ids of the users from facebook post
    # that should see post in their feed.
    Timeline = Struct.new(:name, :artist, :feed_type, :itunes_link, :description,
                          :identifier, :author, :user_identifier, :artist_identifier,
                          :published_at, :likes_count, :picture, :source_link,
                          :youtube_id, :youtube_link, :message, :album, :stream, :link,
                          :import_source, :author_picture, :category, :to, :view_count)

  end
end
