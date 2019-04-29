module Friendable

  def self.included(base)
    base.class_eval do
      before_destroy do
        user_friends.destroy_all
      end

      def user_friends
        UserFriend.where('user_friends.friend1_id = ? OR user_friends.friend2_id = ?', id, id)
      end

      def friends
        User
        .where("users.id != ?", id)
        .joins("INNER JOIN user_friends ON user_friends.friend1_id=users.id OR user_friends.friend2_id=users.id")
        .where('user_friends.friend1_id = ? OR user_friends.friend2_id = ?', id, id)
        .select("DISTINCT(users.*)")
      end

      def friends_of_friends(friend_ids = self.friends.pluck(:id))
        UserFriend.where("(user_friends.friend1_id IN (?) OR user_friends.friend2_id IN (?))", friend_ids, friend_ids)
      end

      def friend!(user)
        user_friend = UserFriend
        .where(<<-SQL
        (user_friends.friend1_id = ? AND user_friends.friend2_id = ?) OR
        (user_friends.friend2_id = ? AND user_friends.friend1_id = ?)
        SQL
          .squish, id, user.id, id, user.id)
        .first
        user_friend ||= UserFriend.new

        return user_friend if user_friend.persisted?

        user_friend.friend1_id = id
        user_friend.friend2_id = user.id
        user_friend.save!

        sql_increment!(
          [
            {
              name: :friends_count,
              by: 1,
            },
          ]
        )

        user_friend
      end
    end
  end

end

