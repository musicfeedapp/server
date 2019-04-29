# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_friend do
    friend1_id 1
    friend2_id 1
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
