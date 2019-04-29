FactoryGirl.define do
  factory :artist, class: 'User', parent: :user do
    first_name 'Kate'
    last_name  'Watson'
    username "KateWatson"
    user_type 'artist'
    facebook_id '333'
  end
end

# == Schema Information
#
# Table name: artists
#
#  id            :integer          not null, primary key
#  facebook_link :text
#  avatar_url    :text
#  description   :text
#  name          :string(255)
#  username      :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#  enabled       :boolean          default(FALSE)
#  twitter_link  :string
#  facebook_id   :string
#  website       :string
#  likes_count   :integer
#  likes         :integer          default([]), is an Array
#  genres        :string           default([]), is an Array
#
# Indexes
#
#  index_artists_on_enabled  (enabled)
#  index_artists_on_genres   (genres)
#  index_artists_on_likes    (likes)
#
