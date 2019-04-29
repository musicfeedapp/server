module Aggregator
  module Recognize

    Youtube = Struct.new(:artist, :track) do
      include Aggregator::Search::YoutubeSearch

      def name
        "#{artist} - #{track}"
      end

      def parts
        [artist, track]
      end

      def valid?
        !video.title.nil?
      end

      def youtube_id
        @youtube_id ||= Aggregator::Providers::Youtube::Link.id(video.player_url)
      end

      def youtube_url
        @youtube_url ||= Aggregator::Providers::Youtube::Link.link(youtube_id)
      end

      def picture
        "https://img.youtube.com/vi/#{youtube_id}/hqdefault.jpg"
      end

      def attributes
        return {} unless valid?

        {
          name: video.title,
            link: video.player_url,
            picture: picture,
            import_source: 'feed',
            artist: artist,
            feed_type: 'youtube',
            published_at: Date.today,
            youtube_link: video.player_url,
        }
      end
    end

  end
end
