module Facebook
  module Proposals
    module Friends
      def create(user, friends, friends_facebook_ids, allowed_facebook_ids, options)
        friends_creation = UsersCreation.new(friends)
        friends_creation.build!(allowed_facebook_ids, user_type: 'user')

        user_ids = UsersCreation.create do |collector|
          collector.concat(friends_creation.values)
        end

        user_ids = user_ids.to_a.map { |row| row['id'] }
        PushNotifications::Worker.perform_async(:friend_joined, [user.id, user_ids]) if user_ids.size > 0

        friends_existing_user_ids = user.friends.pluck(:id)
        friends_relation = FriendRelation.new(user, friends_facebook_ids)
        friends_relation.build!(friends_existing_user_ids)

        followers_existing_user_ids = user.followed.pluck(:id)
        followers_relation = FollowerRelation.new(user, friends_facebook_ids)
        followers_relation.build!(followers_existing_user_ids)

        User.transaction do
          FriendRelation.create do |collector|
            collector.concat(friends_relation.values)
          end

          if options[:new_user]
            FollowerRelation.create do |collector|
              collector.concat(followers_relation.values)
            end
          end
        end
      end
      module_function :create
    end
  end
end
