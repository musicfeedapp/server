module Facebook
  module Proposals

    FollowerRelation = Struct.new(:user, :followers_facebook_ids) do
      def values
        @values ||= []
      end

      def build!(allowed_ids)
        followers_ids.each do |user_id|
          next if allowed_ids.include?(user_id)

          values.push("(#{user.id}, #{user_id})")
        end
      end

      def unfollowed_ids
        UserFollower.where(follower_id: user.id, is_followed: false)
          .joins("INNER JOIN users ON user_followers.followed_id=users.id")
          .uniq
          .pluck(:facebook_id)
      end

      def followers_ids
        @followers_ids ||= begin
                           ids = followers_facebook_ids - user.followed.map(&:facebook_id) - unfollowed_ids
                           return [] if ids.blank?
                           User.where("users.facebook_id IN (?)", ids).pluck('id')
                         end
      end

      def self.create
        values = []

        yield(values)

        return unless values.present?

        UserFollower.connection.execute <<-SQL
          INSERT INTO user_followers ("follower_id", "followed_id") VALUES
            #{values.join(", ")};
        SQL
        .squish
      end

      def size
        values.size
      end
    end

  end
end

