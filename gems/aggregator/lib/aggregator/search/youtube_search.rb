# -*- coding: utf-8 -*-
# encoding: UTF-8

require 'yourub'
require 'yt'

Yt.configure do |config|
  config.api_key = Settings.youtube.developer_key
  config.log_level = :debug
end

module Aggregator
 module Search

   class NoVideo
     def categories ; [] ; end
     def thumbnails ; [] ; end
     def player_url ; "" ; end
     def title ; "" ; end
   end

   Video = Struct.new(:player_url, :thumbnails, :categories, :attributes) do
     def unique_id
       @unique_id ||= Timeline::YoutubeLink.id(player_url)
     end

     def title
       attributes['title']
     end

     def description
       attributes['description']
     end

     def published_at
       attributes['publishedAt']
     end
   end

    module YoutubeSearch
      def youtube_id
        @youtube_id ||= Aggregator::Providers::Youtube::Link.id(youtube_link)
      end

      def youtube_link
        @youtube_link ||= Aggregator::Providers::Youtube::Link.normalize_link(video.player_url)
      end

      private

      def video
        @video ||= begin
                     videos = []

                     client.search(query: name, category: 'music', order: 'relevance', max_results: 10) do |response|
                       attributes = client.get(response['id'])['snippet']

                       videos << Video.new(
                                           Aggregator::Providers::Youtube::Link.link(response['id']),
                                           response['thumbnails'],
                                           ['music'],
                                           attributes,
                                          )
                     end

                     v = if respond_to?(:parts)
                        videos.find { |v| parts.all? { |p| v.title.downcase.include?(p.downcase) } }
                     else
                       videos.first
                     end

                     v || NoVideo.new
                   rescue OpenURI::HTTPError, StandardError
                     NoVideo.new
                   end
      end

      # Example:
      #
      # {"kind"=>"youtube#video",
      # "etag"=>
      #  "\\"xmg9xJZuZD438sF4hb-VcBBREXc/WnkaSe5qIuS12m48v1ymA3Qh_A8\\"",
      # "id"=>"vMCbJB4yNXo",
      # "snippet"=>
      #  {"publishedAt"=>"2009-10-27T01:50:43.000Z",
      #   "channelId"=>"UCDj64sior23IP_7xLe8R7sg",
      #   "title"=>"Static-X - The Only (Video)",
      #   "description"=>"¬© 2005 WMG\\nThe Only (Video)",
      #   "thumbnails"=>
      #    {"default"=>
      #      {"url"=>"https://i.ytimg.com/vi/vMCbJB4yNXo/default.jpg",
      #       "width"=>120,
      #       "height"=>90},
      #     "medium"=>
      #      {"url"=>"https://i.ytimg.com/vi/vMCbJB4yNXo/mqdefault.jpg",
      #       "width"=>320,
      #       "height"=>180},
      #     "high"=>
      #      {"url"=>"https://i.ytimg.com/vi/vMCbJB4yNXo/hqdefault.jpg",
      #       "width"=>480,
      #       "height"=>360}},
      #   "channelTitle"=>"Warner Bros. Records",
      #   "categoryId"=>"10",
      #   "liveBroadcastContent"=>"none",
      #   "localized"=>
      #    {"title"=>"Static-X - The Only (Video)",
      #     "description"=>"¬© 2005 WMG\\nThe Only (Video)"}},
      # "statistics"=>
      #  {"viewCount"=>"6527333",
      #   "likeCount"=>"41273",
      #   "dislikeCount"=>"452",
      #   "favoriteCount"=>"0",
      #   "commentCount"=>"5605"}}
      def videos
        @videos ||= begin
                      videos = []

                      client.search(query: name, category: 'music', order: 'viewCount', max_results: 10) do |response|
                        attributes = client.get(response['id'])['snippet']

                        videos << Video.new(
                                            Aggregator::Providers::Youtube::Link.link(response['id']),
                                            attributes['thumbnails'],
                                            ['music'],
                                            attributes,
                                           )
                      end

                      videos
                    rescue OpenURI::HTTPError, StandardError
                      []
                    end
      end

      # 221646591235273 - Majesic Casual

      def yt_video(youtube_id)
        @yt_video ||= begin
                        begin
                          video = Yt::Video.new(id: youtube_id)
                          # try to fetch data
                          video.title
                          video
                        rescue Yt::Errors::NoItems => boom
                          # nothing to do, no categories found for this record.
                        end
                      end
      end

      def view_count(youtube_id)
        @view_count ||= yt_video(youtube_id).view_count
      end

      def categories(youtube_id)
        @categories ||= begin
                          begin
                            video = yt_video(youtube_id)

                            duration = video.duration
                            category = video.video_category.title.downcase

                            if duration > 60 && (
                              category.include?('music') ||
                                category.include?('entertainment') &&
                                ['221646591235273'].include?((attributes['from'] || {})['id'])
                              )

                              ['music']
                            else
                              []
                            end
                          rescue Yt::Errors::NoItems => boom
                            []
                          end
                        end
      end

      def client
        @client ||= Yourub::Client.new(Settings.youtube.to_h)
      end
    end

  end
end
