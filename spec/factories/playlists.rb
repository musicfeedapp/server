# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :playlist do
    title { |i| "Playlist #{i}" }
    user_id 1
    is_private false
  end
end

# == Schema Information
#
# Table name: playlists
#
#  id            :integer          not null, primary key
#  title         :string(255)
#  user_id       :integer
#  created_at    :datetime
#  updated_at    :datetime
#  timelines_ids :integer          default([]), is an Array
#  picture_url   :text
#  is_private    :boolean          default(FALSE), not null
#  import_source :string
#
# Indexes
#
#  index_playlists_on_is_private       (is_private)
#  index_playlists_on_user_id          (user_id)
#  playlists_timelines_ids_rdtree_idx  (timelines_ids)
#
