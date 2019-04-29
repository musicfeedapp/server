require 'rspotify'

class ImportPlaylistsWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)

    attributes = user.authentications.facebook.client.get_connections('me', 'music.playlists')
    return if attributes.blank?

    attributes.each do |attribute|
      begin
        publish_time = attribute['publish_time']

        attribute = attribute['data']

        # Now we are supporting only spotify playlists.
        next unless attribute['playlist']['url'].include?("open.spotify.com")

        # Example: http://open.spotify.com/user/1116137939/playlist/6sH311NgErhpaOD23tBlmM
        attribute['playlist']['url'] =~ /\/user\/(\w+)\/playlist\/(\w+)$/
        user_id, playlist_id = $1, $2

        playlist = RSpotify::Playlist.find(user_id, playlist_id)

        db_playlist = Playlist.find_or_create_by!(
          user_id: user.id,
          title: playlist.name,
          import_source: 'music.playlists',
        )
        db_playlist.current_user = user

        timelines = playlist.tracks.map do |track|
          begin
            picture = begin
                        image = track.album.images.sort_by { |i| i['height'] }.last

                        if image
                          image['url']
                        end
                      end

            spotify_attributes = Aggregator::Providers::Spotify::Attributes.new(
              'link'        => track.external_urls['spotify'],
              'picture'     => picture,
            )
            next unless spotify_attributes.valid?

            facebook_attributes = Aggregator::Providers::Facebook::Attributes.new(
              'id'              => track.uri,
              'name'            => track.name,
              'author'          => user.name,
              'user_identifier' => user.facebook_id,
              'author_picture'  => "http://graph.facebook.com/#{user.facebook_id}/picture?type=normal",
              'published_at'    => publish_time,
              'from'            => { 'id' => user.facebook_id, 'name' => user.name },
            )
            next unless facebook_attributes.valid?

            builder = Aggregator::Models::TimelineBuilder.new(facebook_attributes, spotify_attributes)
            timeline = builder.build_for(Timeline::TYPES[:spotify])

            track.artists.each do |artist_attributes|
              if artist = User.artist.where(name: artist_attributes.name).first
                timeline.artist_identifier = artist.facebook_id
                break
              end

              timeline.name = "#{artist_attributes.name} - #{timeline.name}"
            end
            timeline.import_source = 'music.playlists'

            timeline = Timeline.new(timeline.as_json)
            timeline.save!
          rescue => boom
            Notification.notify(boom)
          end

          timeline
        end.compact

        db_playlist.add_timeline(timelines.map(&:id))
      rescue => boom
        Notification.notify(boom)
      end
    end
  end
end
