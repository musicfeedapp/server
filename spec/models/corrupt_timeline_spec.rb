require 'spec_helper'

describe CorruptTimeline do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
#
# Table name: corrupt_timelines
#
#  id                        :integer          not null, primary key
#  name                      :string
#  description               :string
#  link                      :string
#  picture                   :text
#  user_identifier           :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  published_at              :datetime
#  feed_type                 :string
#  identifier                :string
#  author                    :string
#  youtube_id                :string
#  likes_count               :integer
#  author_picture            :string
#  artist                    :string
#  album                     :string
#  source                    :string
#  source_link               :string
#  youtube_link              :string
#  restricted_users          :integer          default([]), is an Array
#  likes                     :integer          default([]), is an Array
#  enabled                   :boolean          default(TRUE)
#  font_color                :string
#  artist_identifier         :string
#  genres                    :string           default([]), is an Array
#  comments_count            :integer          default(0)
#  itunes_link               :string
#  stream                    :string
#  default_playlist_user_ids :integer          default([]), is an Array
#  activities_count          :integer
#  import_source             :string           default("feed")
#  category                  :string
#  playlist_ids              :integer          default([]), is an Array
#  timeline_id               :integer
#
