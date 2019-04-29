class UpdateFeedAppIconCountWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :heavy, :retry => false, :unique => :while_executing

  UserFeedCounter = Struct.new(:user) do
    def followed_ids
      @followed_ids ||= user.followed.pluck("id")
    end

    def facebook_ids
      @facebook_ids ||= User.where(id: followed_ids).pluck("facebook_id").map(&:to_s)
    end

    def followers_timelines
      @followers_timelines ||= Timeline
                             .joins("INNER JOIN timeline_publishers ON timeline_publishers.timeline_id=timelines.id")
                             .where("timeline_publishers.user_identifier IN (?)", facebook_ids)
                             .where("timelines.created_at > ?", last_feed_viewed_at_tracker)
    end

    # def user_likes
    #   @user_likes ||= UserLike.where("user_id IN (?) AND created_at > ?", followed_ids, last_feed_viewed_at_tracker)
    # end

    def user_timelines
      @user_timelines ||= Timeline
                        .joins("JOIN timeline_publishers ON timeline_publishers.timeline_id=timelines.id")
                        .where("timeline_publishers.user_identifier = ?", user.facebook_id)
                        .where("timelines.created_at > ?", last_feed_viewed_at_tracker)
    end

    def perform
      (user_timelines.to_a + followers_timelines.to_a).uniq.size
    end

    private


    def last_feed_viewed_at_tracker
      # last_feed_viewed
      Cache.get("lfv:#{user.facebook_id}") || user.last_feed_viewed_at
    end
  end

  class FeedCountWorker
    include Sidekiq::Worker

    sidekiq_options :queue => :heavy, :retry => false, :unique => :while_executing

    def perform(ids)
      ids.each do |id|
        user = User.find(id)

        feed_counter = UserFeedCounter.new(user)
        feed_count   = feed_counter.perform


        if feed_count > 0
          PushNotifications::Worker.perform_async(:feed_count, [user.id, feed_count])
        end
      end
    end
  end

  def perform
    User.user.pluck(:id).each_slice(1000) do |ids|
      FeedCountWorker.perform_async(ids)
    end
  end
end
