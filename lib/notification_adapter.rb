NotificationAdapter = Struct.new(:user) do
  def notitications
    @notifications ||= user.notifications.order("created_at DESC")
  end

  def unreviewed_notifications
    @unreviewed_notifications ||= user.notifications
      .where(status: UserNotification.statuses["NEW"])
      .where("user_notifications.alert_type NOT IN ('track_posted')")
  end

  def unreviewed_notifications_count
    unreviewed_notifications.count
  end
end
