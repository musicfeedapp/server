FactoryGirl.define do
  factory :user_notification do
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
