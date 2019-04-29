FactoryGirl.define do
  sequence :identifier do |n|
    "id-#{n}"
  end

  factory :timeline do
    name             "Yellowcard"
    description      "Yellowcard on Spotify"
    picture          "http://example.com/1.jpg"
    link             'http://example.com'
    feed_type        'soundcloud'
    identifier
    published_at      DateTime.now
    album             'Yellowcard Best Songs'
    artist            'Yellowcard'

    after :create do |timeline|
      timeline.comments.create!(
        commentable: timeline,
        eventable_type: 'Timeline',
        eventable_id: 'published',
        user: timeline.user,
        created_at: Date.today,
      )

      # by default we should have publisher here.
      timeline.timeline_publishers.find_or_create_by(
        user_identifier: timeline.user.facebook_id,
        timeline_id: timeline.id,
      )
    end
  end

  factory :soundcloud, parent: :timeline do
    feed_type 'soundcloud'
  end

  factory :spotify, parent: :timeline do
    feed_type 'spotify'
  end

  factory :youtube, parent: :timeline do
    feed_type 'youtube'
  end
end

# == Schema Information
#
# Table name: timelines
#
#  id                        :integer          not null, primary key
#  name                      :string(255)
#  description               :text
#  link                      :text
#  picture                   :text
#  created_at                :datetime
#  updated_at                :datetime
#  feed_type                 :string(255)      not null
#  identifier                :string(255)
#  likes_count               :integer          default(0)
#  published_at              :datetime
#  youtube_id                :string(255)
#  enabled                   :boolean          default(TRUE)
#  artist                    :string(255)
#  album                     :string(255)
#  source                    :string(255)
#  source_link               :text
#  youtube_link              :string(255)
#  restricted_users          :integer          default([]), is an Array
#  likes                     :integer          default([]), is an Array
#  font_color                :string
#  genres                    :string           default([]), is an Array
#  comments_count            :integer          default(0)
#  itunes_link               :string
#  stream                    :text
#  default_playlist_user_ids :integer          default([]), is an Array
#  activities_count          :integer          default(0)
#  import_source             :string           default("feed")
#  category                  :string
#  view_count                :integer          default(0)
#  change_view_count         :integer          default(0)
#
# Indexes
#
#  index_timeline_publishers_on_created_at_desc                    (created_at)
#  index_timelines_on_created_at                                   (created_at)
#  index_timelines_on_feed_type                                    (feed_type)
#  index_timelines_on_id_asc                                       (id)
#  index_timelines_on_identifier                                   (identifier)
#  index_timelines_on_published_at_desc                            (published_at)
#  index_timelines_on_source_link                                  (source_link)
#  index_timelines_on_youtube_link                                 (youtube_link)
#  index_timelines_on_youtube_link_and_source_link_and_identifier  (youtube_link,source_link,identifier)
#  timelines_identifier_unique_contraint                           (identifier) UNIQUE
#  timelines_likes_rdtree_idx                                      (likes)
#
