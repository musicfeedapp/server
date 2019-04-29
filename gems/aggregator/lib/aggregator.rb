# -*- coding: utf-8 -*-
# encoding: UTF-8

require 'aggregator/version'

require 'aggregator/settings'
require 'aggregator/facebook_applications'
require 'aggregator/facebook_application_queue'

require 'aggregator/nullable/connection'

require 'aggregator/models/timeline'
require 'aggregator/models/timeline_builder'

require 'aggregator/appender'

require 'aggregator/search/youtube_search'
require 'aggregator/search/spotify_search'
require 'aggregator/search/soundcloud_search'
require 'aggregator/search/shazam_search'
require 'aggregator/search/itunes_search'

require 'aggregator/recognize/youtube'
require 'aggregator/recognize/spotify'
require 'aggregator/recognize/itunes'

require 'aggregator/providers/facebook/connection'
require 'aggregator/providers/facebook/attributes'

require 'aggregator/providers/grooveshark/finder'
require 'aggregator/providers/grooveshark/attributes'
require 'aggregator/providers/grooveshark/link'

require 'aggregator/providers/spotify/finder'
require 'aggregator/providers/spotify/attributes'
require 'aggregator/providers/spotify/link'

require 'aggregator/providers/shazam/finder'
require 'aggregator/providers/shazam/attributes'
require 'aggregator/providers/shazam/link'

require 'aggregator/providers/soundcloud/finder'
require 'aggregator/providers/soundcloud/attributes'
require 'aggregator/providers/soundcloud/link'

require 'aggregator/providers/youtube/finder'
require 'aggregator/providers/youtube/attributes'
require 'aggregator/providers/youtube/link'

require 'aggregator/providers/mixcloud/finder'
require 'aggregator/providers/mixcloud/attributes'
require 'aggregator/providers/mixcloud/link'

require 'aggregator/workers/base_worker'
require 'aggregator/workers/node_worker'
require 'aggregator/workers/storage_worker'

require 'aggregator/notification'

require 'aggregator/boot'

require 'redis'
require 'base64'
# require 'facets'

module Aggregator

  module Providers
  end

  module Workers
  end

  module Search
  end

  class FacebookClientError < Exception ; end

  FIELDS = "fields=id,name,picture,description,link,from,created_time,application,comments.limit(1).summary(true),to,likes.limit(1).summary(true),story_tags"
  FEED_QUERY = "feed?#{Aggregator::FIELDS}"
  POSTS_QUERY = "posts?#{Aggregator::FIELDS}"


  def self.register_plugin(name, klass)
    plugins_storage[name].push(klass)
  end

  def self.plugins(name)
    plugins_storage[name]
  end

  def self.plugins_storage
    @@plugins_storage ||= Hash.new { |h,k| h[k] = [] }
  end

  RedisConnection = -> {
    uri = URI.parse(Settings.redis.url)

    Redis.new(
      :host        => uri.host,
      :port        => uri.port,
      :password    => uri.password,
      :thread_safe => true,
    )
  }

  def self.redis
    @redis ||= RedisConnection.call
  end

  ApiConnection= -> {
    if Settings.development?
      Faraday.new(url: "http://localhost:3003") do |faraday|
        faraday.adapter  Faraday.default_adapter
      end
    else
      Faraday.new(url: "http://musicfeed-api.rubyforce.co") do |faraday|
        faraday.adapter  Faraday.default_adapter
      end
    end
  }

  KeyValueAdapter = Struct.new(:db) do
    def force_encoding!(attributes)
      if attributes.is_a?(Array)
        attributes.each_with_index do |v, i|
          attributes[i] = force_encoding!(v)
        end
      elsif attributes.is_a?(Hash)
        attributes.update_values do |v|
          if v.is_a?(Hash)
            force_encoding!(v)
          elsif v.is_a?(Array)
            v.each_with_index { |c,i| v[i] = force_encoding!(c) }
            v
          elsif v.is_a?(String)
            v.force_encoding("ISO-8859-1").encode("UTF-8")
          else # otherwise we should have always the same output
            v
          end
        end
      elsif attributes.is_a?(String)
        attributes = attributes.force_encoding("ISO-8859-1").encode("UTF-8")
      else # otherwise we should always have the same output
        attributes
      end

      attributes
    end

    def set(attributes)
      id = db.save_doc(value: 'ag')['id']
      doc = db.get(id)

      begin
        attributes = attributes.to_json
      rescue
        attributes = force_encoding!(attributes)
        attributes = attributes.to_json
      end

      attributes = Base64.encode64(attributes)
      doc.put_attachment('attrs', attributes)
      id
    end

    def get(id)
      doc = db.get(id)
      attributes = doc.fetch_attachment('attrs')
      attributes = Base64.decode64(attributes)
      attributes = JSON.parse(attributes)
      attributes
    end

    def del(id)
      db.delete_doc(db.get(id))
      # db.compact!
    end
  end

  KeyValueApi = Struct.new(:db) do
    def force_encoding!(attributes)
      if attributes.is_a?(Array)
        attributes.each_with_index do |v, i|
          attributes[i] = force_encoding!(v)
        end
      elsif attributes.is_a?(Hash)
        attributes.update_values do |v|
          if v.is_a?(Hash)
            force_encoding!(v)
          elsif v.is_a?(Array)
            v.each_with_index { |c,i| v[i] = force_encoding!(c) }
            v
          elsif v.is_a?(String)
            v.force_encoding("ISO-8859-1").encode("UTF-8")
          else # otherwise we should have always the same output
            v
          end
        end
      elsif attributes.is_a?(String)
        attributes = attributes.force_encoding("ISO-8859-1").encode("UTF-8")
      else # otherwise we should always have the same output
        attributes
      end

      attributes
    end

    def get(id)
      response = db.get("/mnesia/#{id}") do |config|
        config.options.timeout = 30
        config.options.open_timeout = 30
      end

      raise "No success on getting attributes by id: #{id}, status code: #{response.status}" if response.status != 200

      attributes = JSON.parse(attributes)
      attributes
    end

    def set(attributes)
      begin
        attributes = attributes.to_json
      rescue
        attributes = force_encoding!(attributes)
        attributes = attributes.to_json
      end

      response = db.post('/mnesia') do |config|
        config.headers["Content-Type"] = "application/json"
        config.body = "{\"attributes\":\"#{attributes}\"}"
        config.options.timeout = 30
        config.options.open_timeout = 30
      end

      raise "No success on storing attributes, status code: #{response.status}" if response.status != 200

      response.body
    end

    def del(id)
      response = db.delete("/mnesia/#{id}") do |config|
        config.options.timeout = 30
        config.options.open_timeout = 30
      end

      raise "No success on deleting attributes, status code: #{response.status}" if response.status != 200

      response
    end
  end

  # Lets force to create new connection all the time.
  def self.client
    KeyValueApi.new(ApiConnection.call)
  end

  def self.providers
    @providers ||= [
      Aggregator::Providers::Grooveshark::Link,
      Aggregator::Providers::Mixcloud::Link,
      Aggregator::Providers::Shazam::Link,
      Aggregator::Providers::Soundcloud::Link,
      Aggregator::Providers::Spotify::Link,
      Aggregator::Providers::Youtube::Link
    ]
  end
end
