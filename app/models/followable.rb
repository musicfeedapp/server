module Followable

  def self.included(base)
    base.class_eval do
      has_many :followers, through: :user_followers
      has_many :user_followers, -> { where(is_followed: true) }, foreign_key: 'followed_id', primary_key: 'id', class_name: 'UserFollower', dependent: :destroy

      has_many :followed, through: :user_followed
      has_many :user_followed, -> { where(is_followed: true) }, foreign_key: 'follower_id', primary_key: 'id', class_name: 'UserFollower', dependent: :destroy

      def follow!(user)
        if index = restricted_users.index(user.facebook_id.to_s)
          self.restricted_users.delete_at(index)
          restricted_users_will_change!
          save!
        end

        scoped = UserFollower.where(follower_id: id, followed_id: user.id)

        if scoped.exists?
          scoped.update_all(is_followed: true)
        else
          user_follower = UserFollower.find_or_initialize_by(follower_id: id, followed_id: user.id)
          user_follower.is_followed = true
          user_follower.save!
        end

        user.sql_increment!([{name: :followers_count, by: 1}])
        sql_increment!([{name: :followed_count, by: 1}])
      end

      def unfollow!(user)
        UserFollower
          .where(follower_id: id, followed_id: user.id)
          .update_all(is_followed: false)

        user.sql_increment!([{name: :followers_count, by: -1}])
        sql_increment!([{name: :followed_count, by: -1}])
      end

      def bulk_follow!(user_ids, options={})
        user_ids = user_ids - self.followed.pluck(:followed_id)

        if user_ids.present?
          mapped_ids = user_ids.map{ |user_id| "(#{self.id}, #{user_id}, true)" }

          UserFollower.connection.execute(<<-SQL
            INSERT INTO user_followers("follower_id", "followed_id", "is_followed")
            VALUES
            #{mapped_ids.join(", ")}
            SQL
          .squish)

          User.connection.execute(<<-SQL
            UPDATE users
            SET followers_count = followers_count + 1
            WHERE id IN (#{user_ids.join(", ")})
            SQL
            .squish)

          self.sql_increment!([{ name: :followed_count, by: user_ids.size }])

          PushNotifications::Worker.perform_async(:artist_added, [self.id, user_ids]) if options[:follow_user].blank?
        end

        if user_ids.size > 0 && options[:follow_user].present?
          user_ids.each do |who_id|
            PushNotifications::Worker.perform_async(:follow, [self.id, who_id])
          end
        end
      end
    end
  end

end
