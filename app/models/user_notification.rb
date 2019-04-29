class UserNotification < ActiveRecord::Base
  belongs_to :playlist
  belongs_to :timeline
  belongs_to :sender, foreign_key: 'from_user_id', primary_key: 'id', class_name: 'User'
  belongs_to :comment

  enum status: {
    "NEW"  => 0,
    "SEEN" => 1,
    "READ" => 2
  }

  def related_to_timeline?
    %w(like add_to_playlist add_comment).include?(self.alert_type)
  end
end

# == Schema Information
#
# Table name: user_notifications
#
#  id           :integer          not null, primary key
#  to_user_id   :integer
#  from_user_id :integer
#  message      :string
#  alert_type   :string
#  comment      :string
#  timeline_id  :integer
#  playlist_id  :integer
#  comment_id   :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  status       :integer          default(0)
#  artist_ids   :text             default([]), is an Array
#
# Indexes
#
#  index_user_notifications_on_alert_type       (alert_type)
#  index_user_notifications_on_created_at_desc  (created_at)
#  index_user_notifications_on_status           (status)
#
