# == Schema Information
#
# Table name: user_songs
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  created_at  :datetime
#  updated_at  :datetime
#  timeline_id :integer
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_song do
    user_id 1
    timeline_id 1
  end

  factory :youtube_user_song, parent: :user_song do
    timeline_id { create(:timeline).id }
  end
end
