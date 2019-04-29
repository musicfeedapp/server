require 'spec_helper'

describe Timeline do

  describe '.timeline_publishers' do
    let(:user) { create(:user) }

    it 'should allow to get users' do
      user1 = create(:user, facebook_id: 'facebook-1')
      user2 = create(:user, facebook_id: 'facebook-2')

      timeline = create(:timeline, user: user1)
      expect(timeline.publishers).to eq([user1])

      timeline.timeline_publishers.create(user: user2, timeline_id: timeline.id)
      timeline.reload
      expect(timeline.publishers.to_a).to include(user1)
      expect(timeline.publishers.to_a).to include(user2)
    end
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
