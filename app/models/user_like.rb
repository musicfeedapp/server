class UserLike < ActiveRecord::Base
  belongs_to :user
  belongs_to :timeline

  has_one :comment, :as => :eventable
end

# == Schema Information
#
# Table name: user_likes
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  timeline_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_user_likes_on_timeline_id  (timeline_id)
#  index_user_likes_on_user_id      (user_id)
#  index_user_likeson_created_at    (created_at)
#
