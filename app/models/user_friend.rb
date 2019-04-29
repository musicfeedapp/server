class UserFriend < ActiveRecord::Base
  belongs_to :friend1, class_name: 'User'
  belongs_to :friend2, class_name: 'User'

  # TODO: move it to the friendable module
  def self.user_friends_by(id)
    UserFriend.where('user_friends.friend1_id = ? OR user_friends.friend2_id = ?', id, id)
  end
end

# == Schema Information
#
# Table name: user_friends
#
#  id         :integer          not null, primary key
#  friend1_id :integer
#  friend2_id :integer
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_user_friends_on_friend1_id                 (friend1_id)
#  index_user_friends_on_friend1_id_and_friend2_id  (friend1_id,friend2_id) UNIQUE
#  index_user_friends_on_friend2_id                 (friend2_id)
#  index_user_friends_on_friend2_id_and_friend1_id  (friend2_id,friend1_id) UNIQUE
#
