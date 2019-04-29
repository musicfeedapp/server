module TimelinesRecognize

  # Youtube search by id and making timeline attributes as hash
  Youtube = Struct.new(:youtube_id) do
    include Aggregator::Search::YoutubeSearch

    # TODO: extract it to Attributes module inside YoutubeSearch

    def video
      @video ||= Yt::Video.new(id: youtube_id)
    end

    def category
      @category ||= video.video_category.title.downcase
    end

    def link
      @link ||= Aggregator::Providers::Youtube::Link.link(youtube_id)
    end

    def picture
      "https://i.ytimg.com/vi/#{youtube_id}/hqdefault.jpg"
    end

    def attributes
      # TODO: add white list filter for majestic casual
      return {} if !video.respond_to?(:title) || category != 'music'
      return {} if video.title.blank?

      {
        name: video.title,
        category: category,
        link: link,
        picture: picture,
        youtube_link: link,
        youtube_id: youtube_id,
        published_at: Date.today,
        import_source: 'feed',
        feed_type: 'youtube',
      }
    end
  end

  Spotify = Struct.new(:spotify_id) do
    include Aggregator::Search::SpotifySearch

    def attributes
      return {} unless track.valid?

      {
        name: track.name,
        link: track.link,
        picture: track.picture,
        import_source: 'feed',
        feed_type: 'spotify',
        published_at: Date.today,
        artist: track.artist
      }
    end
  end

  Soundcloud = Struct.new(:soundcloud_id) do
    include Aggregator::Search::SoundcloudSearch

    def attributes
      return {} unless track.valid?

      {
        name: track.name,
        link: track.link,
        picture: track.picture,
        import_source: 'feed',
        feed_type: 'soundcloud',
        published_at: Date.today
      }
    end
  end

  Shazam = Struct.new(:shazam_id) do
    include Aggregator::Search::ShazamSearch

    def attributes
      return {} unless track.valid?

      {
        name: track.name,
        link: track.link,
        picture: track.picture,
        artist: track.artist,
        import_source: 'feed',
        feed_type: 'shazam',
        published_at: Date.today
      }
    end
  end

  def self.do(request_attributes)
    # timeline object for recognizing as result.
    timeline = nil

    url = request_attributes[:url]
    if url
      if id = Aggregator::Providers::Youtube::Link.id(url)
        timeline = Timeline.new(Youtube.new(id).attributes)
        return timeline if timeline
      end

      if id = Aggregator::Providers::Spotify::Link.id(url)
        timeline = Timeline.new(Spotify.new(id).attributes)
        return timeline if timeline
      end

      if id = Aggregator::Providers::Soundcloud::Link.id(url)
        timeline = Timeline.new(Soundcloud.new(id).attributes)
        return timeline if timeline
      end

      if id = Aggregator::Providers::Shazam::Link.id(url)
        timeline = Timeline.new(Shazam.new(id).attributes)
        return timeline if timeline
      end
    end

    artist, track = request_attributes[:artist], request_attributes[:track]
    if artist && track
      timeline = Timeline.new(Aggregator::Recognize::Youtube.new(artist, track).attributes)
      return timeline if timeline

      # TODO: make call to search in youtube by artist and track.
      # TODO: add other providers calls as well by it should be done in the different threads.
    end

    # Dont think we reach it with timeline object but lets leave it for more readable way for us.
    # in case of no timeline object we should get nil and service should respond with nothing.
    return timeline
  end

end
