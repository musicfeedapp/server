module Aggregator
  module Recognize

    Spotify = Struct.new(:artist_name, :track_name) do
      def title
        track.name
      end

      def name
        track.name
      end

      def spotify_id
        @spotify_id ||= Aggregator::Providers::Spotify::Link.id(track.uri)
      end

      def spotify_url
        @spotify_url ||= track.uri
      end

      def artist
        track.artists.first.name
      end

      def picture
        track.album.images.sort_by {|a| [a['height'], a['width']]}.last['url']
      end

      def track
        @track ||= RSpotify::Track.search("#{artist_name} - #{track_name}").first
      end

      def valid?
        !track.nil? && !track.name.nil?
      end

      def attributes
        return {} unless valid?

        {
          name: title,
          link: spotify_url,
          picture: picture,
          import_source: 'feed',
          artist: artist,
          feed_type: 'spotify',
          published_at: Date.today
        }
      end
    end

  end
end
