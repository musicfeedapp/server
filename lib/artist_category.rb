ArtistCategory = Struct.new(:artist, :attributes) do
  def move_artist
    if artist.artist? && User::LIKE_TYPES.exclude?(artist.category.to_s.downcase)
      User.transaction do
        timelines_ids = artist.timelines_artist.pluck(:id)
        NonMusicCategoryArtist.create(artist.attributes.merge("facebook_exception" => attributes).except("id", "authenticated", "updated_at", "created_at"))

        artist.timelines_artist.each do |timeline|
          NonMusicArtistTimeline.create(timeline.attributes.except("id", "updated_at", "created_at"))
        end
        
        artist.user_followers.each do |follower|
          non_music_follower = NonMusicArtistFollower.new(follower.attributes.except("id", "updated_at", "created_at"))
          non_music_follower.primary_id_of_user_followers = follower.id
          non_music_follower.save
        end

        Playlist.all.each do |playlist|
          if playlist.timelines_ids.include?(timelines_ids)
            playlist.timelines_ids = playlist.timelines_ids - timelines_ids
            playlist.timelines_ids_will_change!
            playlist.save!
          end
        end
        
        artist.user_followers.delete_all
        artist.timelines_artist.delete_all
        artist.delete
      end
    end
  end
end
