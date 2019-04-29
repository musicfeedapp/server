module Facebook
  module Proposals
    module Followers
      def create(user, artists, artists_facebook_ids, allowed_facebook_ids, options)
        followers_creation = UsersCreation.new(artists)
        followers_creation.build!(allowed_facebook_ids, user_type: 'artist')

        user_ids = UsersCreation.create do |collector|
          collector.concat(followers_creation.values)
        end

        user_ids.to_a.each do |row|
          LOGGER.debug("[Feedler-Facebook::Proposals::Followers] categories: #{ [{id: row['id'], category: row['category']}].inspect }")
        end

        user_ids = user_ids.to_a.map { |row| row['id'] }

        # ArtistLikeArtistWorker.perform_async(user_ids)

        PushNotifications::Worker.perform_async(:artist_added, [user.id, user_ids]) if user_ids.size > 0
        Facebook::Feed::ArtistWorker.perform_async(user_ids.to_a)

        existing_user_ids = user.followed.pluck(:id)
        followers_relation = FollowerRelation.new(user, artists_facebook_ids)
        followers_relation.build!(existing_user_ids)

        User.transaction do
          FollowerRelation.create do |collector|
            collector.concat(followers_relation.values)
          end
        end
      end
      module_function :create
    end
  end
end
