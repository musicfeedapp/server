module Facebook
  module Proposals

    FriendRelation = Struct.new(:user, :facebook_friends_ids) do
      def values
        @values ||= []
      end

      def build!(allowed_ids)
        friends_ids.each do |user_id|
          next if allowed_ids.include?(user_id)

          values.push("(#{user.id}, #{user_id})")
        end
      end

      def friends_ids
        @friends_ids ||= begin
                           ids = facebook_friends_ids - user.friends.user.map(&:facebook_id)
                           return [] if ids.blank?
                           User.where("users.facebook_id IN (?)", ids).pluck('id')
                         end
      end

      def self.create
        values = []

        yield(values)

        return unless values.present?

        UserFollower.connection.execute <<-SQL
          INSERT INTO user_friends ("friend1_id", "friend2_id") VALUES
            #{values.join(", ")};
        SQL
        .squish
      end

      def size
        @values.size
      end
    end

  end
end

