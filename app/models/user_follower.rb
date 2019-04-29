class UserFollower < ActiveRecord::Base
  belongs_to :follower, class_name: 'User'
  belongs_to :followed, class_name: 'User'
end

# == Schema Information
#
# Table name: user_followers
#
#  id          :integer          not null, primary key
#  follower_id :integer
#  followed_id :integer
#  created_at  :datetime
#  updated_at  :datetime
#  is_followed :boolean          default(TRUE)
#
# Indexes
#
#  index_user_followers_on_followed_id  (followed_id)
#  index_user_followers_on_follower_id  (follower_id)
#
