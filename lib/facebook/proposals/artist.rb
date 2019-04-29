require 'timeout'

module Facebook
  module Proposals

    class Worker
      include Sidekiq::Worker

      def perform(artist_id)
        artist = User.find(artist_id)

        artist = Facebook::Proposals::Artist.new(artist)
        artist.find!
      end
    end

    Artist = Struct.new(:artist, :options) do
      include Facebook::Fb::Connection

      def initialize(artist, options = {})
        super(artist, options)
      end

      def auth_token
        Authentication.where('expires_at >= NOW()').first.auth_token
      end

      def facebook_ids
        @facebook_ids ||= begin          
          []
          .concat(artists_facebook_ids)
        end
      end

      def existing_ids
        @existing_ids ||= begin
          if facebook_ids.blank?
            []
          else
            User.where("users.facebook_id IN (?)", facebook_ids).pluck('facebook_id')
          end
        end
      end

      def facebook_accessible?
        begin
            artist_collection
          true
        rescue => boom
          Notification.notify(boom, from: 'Facebook::Proposals::Artist', user_id: artist.id)
          # Facebook::Proposals::Worker.perform_async(user.id)
          false
        end
      end

      def find!
        find_depends_on_timeout!
      end

      def find_depends_on_timeout!
        return false unless facebook_accessible?
        allowed_facebook_ids = facebook_ids - existing_ids
        Followers.create(artist, artists, artists_facebook_ids, allowed_facebook_ids, options)

        ArtistInfoWorker.perform_async(artists)
        true
      rescue => boom
        Notification.notify(boom, from: 'Facebook::Proposals::Artist', user_id: artist.id)

        false
      end

      def artists_facebook_ids
        @artists_facebook_ids ||= artists.map {|o| o['id'].to_s}
      end

      def artists
        a = []
        a.concat(likes.to_a)
        a
      end

      def likes
        @likes ||= begin
                    artist_collection[:likes]
                    .to_a
                    .select do |attributes|
                      User::LIKE_TYPES.include?(attributes['category'].to_s.downcase)
                    end
                  end
      end

      def artist_collection
        { likes: read_all_as_collection(facebook.get_connections(artist.facebook_id, 'likes?fields=id,name,is_verified,category', { api_version: 'v2.3' }))}  
      end
    end

  end
end
