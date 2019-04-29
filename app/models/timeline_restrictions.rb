TimelineRestrictions = Struct.new(:user) do
  def restrict!(timeline)
    Timeline.transaction do
      timeline.restricted_users = (timeline.restricted_users + [user.id]).uniq
      timeline.restricted_users_will_change!
      timeline.save!
    end

    user.unlike!(timeline.id, scoped: -> { Timeline })

    # @note restricted_users = restricted_timelines but for now we are using it
    # as mirror for timelines and users for easy writing sql queries on
    # sorting.
    User.transaction do
      user.restricted_users = user.restricted_users + timeline.timeline_publishers.pluck(:user_identifier).map(&:to_s)
      user.restricted_users_will_change!

      user.restricted_timelines = (user.restricted_timelines + [timeline.id]).uniq
      user.restricted_timelines_will_change!

      user.save!
    end
  end

  def restore!(timeline)
    Timeline.transaction do
      timeline.restricted_users = (timeline.restricted_users - [user.id]).uniq
      timeline.restricted_users_will_change!
      timeline.save!
    end

    User.transaction do
      timeline.timeline_publishers.pluck(:user_identifier).each do |user_identifier|
        if index = user.restricted_users.index(user_identifier.to_s)
          user.restricted_users.delete_at(index)
          user.restricted_users_will_change!
        end
      end

      if index = user.restricted_timelines.index(timeline.id)
        user.restricted_timelines.delete_at(index)
        user.restricted_timelines_will_change!
      end

      user.save!
    end
  end

  TIMES_TO_UNFOLLOW = 3
  def unfollowable?(timeline)
    timeline.timeline_publishers.any? { |tp| user.restricted_users.count(tp.user_identifier.to_s) == TIMES_TO_UNFOLLOW }
  end
end
