class ArtistInfoWorker
  include Sidekiq::Worker

  sidekiq_options retry: 2

  def enqueue(artist)
    ArtistInfoWorker.perform_async(artist)
  end

  def perform(artists)
    if artists.is_a?(Hash)
      update_attributes(artists)
    else
      artists.each do |artist|
        enqueue(artist)
      end
    end
  rescue => boom
    Notification.notify(boom, artists: artists)
    raise boom
  end

  def update_attributes(artist)
    name, facebook_id = artist['name'], artist['id']

    facebook_link = "https://www.facebook.com/#{facebook_id}"
    artist_attributes = ArtistAttributes.new(name, facebook_link, nil)

    LOGGER.debug("[Facebook-ArtistInfoWorker] categories: #{ [{id: artist['id'], category: artist_attributes.category}].inspect }")

    artist = User.artist.find_by(facebook_id: facebook_id.to_s)

    if artist_attributes.genres.present?
      genres = artist_attributes.genres - artist.genres.pluck(:name)

      genres.each do |name|
        # in case if we have genre we should connect existing genre with artist.
        genre = Genre.find_or_create_by(name: name.downcase)

        user_genres = artist.user_genres.to_a
        next if user_genres.any? { |user_genre| user_genre.genre_id == genre.id }

        # user_genres has connection between genre and artist tables.
        artist.user_genres.build(genre_id: genre.id)
      end
    end

    artist.username = artist_attributes.username
    artist.website = artist_attributes.website
    artist.category = artist_attributes.category

    artist.save!

    LOGGER.debug("[Feedler-ArtistInfoWorker] categories: #{ [{id: artist.facebook_id, category: artist.category}].inspect }")
  end
end
