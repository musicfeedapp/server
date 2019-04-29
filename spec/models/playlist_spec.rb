require 'spec_helper'

describe Playlist do
  # it { should belong_to(:user) }

  # it { should validate_presence_of(:title) }
  # it { should validate_presence_of(:user_id) }

  it 'should be possible to get timelines sorted by timelines_ids' do
    user = create(:user)

    timeline1 = create(:timeline, user: user)
    timeline2 = create(:timeline, user: user)
    timeline3 = create(:timeline, user: user)

    playlist = create(:playlist, user: user)
    playlist.current_user = user

    playlist.add_timeline([timeline2.id, timeline3.id, timeline1.id])

    timelines, _activities, _publishers = playlist.reload.timelines
    expect(playlist.reload.picture_url).to eq(timeline2.picture)

    playlist.remove_timeline([timeline2.id])
    expect(playlist.picture_url).to eq(timeline3.picture)
  end

  it 'should create from temp and existing record in the playlist records' do
    Cache.clear

    user = create(:user, facebook_id: 'facebook-id-1')

    timeline_attributes = build(:timeline, name: 'timeline-attributes')
    timeline = create(:timeline, name: 'timeline', user: user)

    Cache.set('custom-id', Marshal.dump(timeline_attributes))

    playlist = create(:playlist, user: user)
    playlist.current_user = user

    playlist.add_timeline([timeline.id, 'custom-id'])

    timelines, _activities, _publishers = playlist.reload.timelines

    names = timelines.map(&:name)
    expect(names.size).to eq(2)
    expect(names).to include('timeline')
    expect(names).to include('timeline-attributes')
  end

  context "when playlist is public" do
    it 'should increase/decrease public playlist timeline count in user on add/remove timeline' do
      user = create(:user)

      timeline1 = create(:timeline, user: user)
      timeline2 = create(:timeline, user: user)
      timeline3 = create(:timeline, user: user)

      playlist = create(:playlist, is_private: false, user: user)
      playlist.current_user = user

      playlist.add_timeline([timeline1.id])
      expect(user.reload.public_playlists_timelines_count).to eq(1)

      playlist.add_timeline([timeline2.id, timeline3.id])
      expect(user.reload.public_playlists_timelines_count).to eq(3)

      playlist.remove_timeline([timeline1.id])
      expect(user.reload.public_playlists_timelines_count).to eq(2)

      playlist.remove_timeline([timeline2.id, timeline3.id])
      expect(user.reload.public_playlists_timelines_count).to eq(0)
    end
  end

  context "when playlist is private" do
    it 'should increase/decrease private playlist timeline count in user on add/remove timeline' do
      user = create(:user)

      timeline1 = create(:timeline, user: user)
      timeline2 = create(:timeline, user: user)
      timeline3 = create(:timeline, user: user)

      playlist = create(:playlist, is_private: true, user: user)
      playlist.current_user = user

      playlist.add_timeline([timeline1.id])
      expect(user.reload.private_playlists_timelines_count).to eq(1)

      playlist.add_timeline([timeline2.id, timeline3.id])
      expect(user.reload.private_playlists_timelines_count).to eq(3)

      playlist.remove_timeline([timeline1.id])
      expect(user.reload.private_playlists_timelines_count).to eq(2)

      playlist.remove_timeline([timeline2.id, timeline3.id])
      expect(user.reload.private_playlists_timelines_count).to eq(0)
    end
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
