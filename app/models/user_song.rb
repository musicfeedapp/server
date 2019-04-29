class UserSong < ActiveRecord::Base
  default_scope -> { order('user_songs.created_at DESC') }

  belongs_to :user, counter_cache: :user_songs_count
  belongs_to :timeline
end

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
