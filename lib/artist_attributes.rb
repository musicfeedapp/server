ArtistAttributes = Struct.new(:name, :facebook_link, :twitter_link) do
  def valid?
    artist['mbid'].present?
  end

  # Lastfm
  def artist
    @artist ||= begin
      # TODO: review this code because of possible problems with
      # genres.
      [name, *name.split(/,/), *name.split(/ /)].uniq.detect do |possible_name|
        begin
          @artist = lastfm.artist.get_info(artist: possible_name)
          return @artist
        rescue Lastfm::ApiError
          # Nothing to do with that.
        end
      end
    end
  end

  def avatar_url
    begin
      return unless artist['image'].present?
    rescue => boom
      Notification.notify(boom, artist: artist)
      raise boom
    end

    unless artist['image'].is_a?(Array)
      return artist['image']
    end

    artist['image'][2]['content']
  end

  def genres
    artist
      .fetch('tags') { {} }
      .fetch('tag') { [] }
      .map { |tag| tag['name'] }
      .compact rescue []
  end

  def username
    # TODO: we should place here something to recognize artist later.
    # something like review object.
    name
  end

  # In case if we don't have facebook id information lets mark artist is
  # disabled users and we should use specific page for manually adding facebook
  # ids for the artists.
  def enabled
    facebook_attributes['id'].present?
  end

  # Facebook attributes
  def facebook_id
    facebook_attributes['id']
  end

  def website
    facebook_attributes['website']
  end

  def likes_count
    facebook_attributes['likes']
  end

  def category
    facebook_attributes['category']
  end

  private

  def lastfm
    @connection ||= Lastfm.new(
      Rails.configuration.lastfm.api_key,
      Rails.configuration.lastfm.secret,
    )
  end

  def facebook_attributes
    @facebook_attributes ||= begin
      begin
        # find facebook attributes(id, website, likes)
        facebook_link =~ /www.facebook.com\/(.+)/
        facebook_id   = $1

        response = Faraday.get("http://graph.facebook.com/#{facebook_id}")
        JSON.parse(response.body)
      rescue # in case if we have no facebook id lets assign nil values for remaining attributes
        {}
      end
    end
  end
end
