require 'timeout'

module Facebook
  module Proposals

    class Worker
      include Sidekiq::Worker

      def perform(user_id)
        user = User.find(user_id)

        maker = Facebook::Proposals::Maker.new(user, in_worker: true)
        maker.find!
      end
    end

    Maker = Struct.new(:user, :options) do
      include Facebook::Fb::Connection

      def initialize(user, options = {})
        super(user, options)
      end

      def auth_token
        user.authentications.facebook.auth_token
      end

      def facebook_ids
        @facebook_ids ||= begin
          []
            .concat(friends_facebook_ids)
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
          collection
          true
        rescue => boom
          Notification.notify(boom, from: 'Facebook::Proposals::Maker', user_id: user.id)
          # Facebook::Proposals::Worker.perform_async(user.id)
          false
        end
      end

      def in_worker?
        options.fetch(:in_worker) { false }
      end

      def only_music?
        options.fetch(:only_music) { false }
      end

      def find!
        find_depends_on_timeout!
      end

      def find_depends_on_timeout!
        return false unless facebook_accessible?

        allowed_facebook_ids = facebook_ids - existing_ids

        Followers.create(user, artists, artists_facebook_ids, allowed_facebook_ids, options)

        unless only_music?
          Friends.create(user, friends, friends_facebook_ids, allowed_facebook_ids, options)
        end

        user.update_attributes!(
          followed_count:   user.user_followed.to_a.size,
          followers_count:  user.user_followers.to_a.size,
          friends_count:    user.friends.count,
        )

        # because of using raw sql for insertations we should generate ext
        # tokens for accessing profiles in the client.
        # ExtTokensWorker.perform_async

        # In case of having the new artists we can match using last.fm provider
        # and then add more information per artist later.
        ArtistInfoWorker.perform_async(artists)

        # We should have up to date all users related to the current user.
        follower_ids = UserFollower.where(follower_id: user.id).pluck(:followed_id)
        IndexerWorker.perform_async("User", :index, follower_ids)

        true
      rescue => boom
        Notification.notify(boom, from: 'Facebook::Proposals::Maker', user_id: user.id)

        unless in_worker?
          Facebook::Proposals::Worker.perform_async(user.id)
        else
          # otherwise we should boom message.
          raise boom
        end

        false
      end

      def friends
        @friends ||= collection[:friends].to_a
      end

      def friends_facebook_ids
        @friends_facebook_ids ||= friends.map {|o| o['id'].to_s}
      end

      def artists_facebook_ids
        @artists_facebook_ids ||= artists.map {|o| o['id'].to_s}
      end

      def artists
        # lets merge artists and music band from liked pages.
        @artists ||= begin
          a = []
          a.concat(music.to_a)
          a.concat(likes.to_a)
          a
        end
      end

      def music
        @music ||= begin
                     collection[:artists]
                     .to_a
                     .select do |attributes|
                       User::LIKE_TYPES.include?(attributes['category'].to_s.downcase)
                     end
                   end
      end

      def likes
        @likes ||= begin
          music_ids = music.to_a.map { |attributes| attributes['id'] }

          collection[:likes]
            .to_a
            .select do |attributes|
              !music_ids.include?(attributes['id']) &&
              User::LIKE_TYPES.include?(attributes['category'].to_s.downcase)
            end
        end
      end

      def collection
        @collection ||= {
          artists: read_all_as_collection(facebook.get_connections('me', 'music', { fields: 'id,email,name,category,is_verified' }, { api_version: 'v2.3' })),
          friends: read_all_as_collection(facebook.get_connections('me', 'friends', { fields: 'id,email,name,is_verified' }, { api_version: 'v2.3' })),
          likes:   read_all_as_collection(facebook.get_connections('me', 'likes', { fields: 'id,email,name,category,is_verified' }, { api_version: 'v2.3' })),
        }
      end
    end

  end
end
