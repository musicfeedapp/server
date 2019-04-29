class TimelinePublisher < ActiveRecord::Base
  belongs_to :user, foreign_key: 'user_identifier', primary_key: 'facebook_id'
  belongs_to :timeline
end

# == Schema Information
#
# Table name: timeline_publishers
#
#  id              :integer          not null
#  user_identifier :string
#  timeline_id     :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_timeline_publishers_on_timeline_id                      (timeline_id)
#  index_timeline_publishers_on_timeline_id_created_at_desc      (timeline_id,created_at)
#  index_timeline_publishers_on_user_identifier                  (user_identifier)
#  index_timeline_publishers_on_user_identifier_and_timeline_id  (user_identifier,timeline_id) UNIQUE
#
