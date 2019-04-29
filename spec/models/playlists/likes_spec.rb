require 'spec_helper'

module Playlists
  describe Likes do

    it 'should returns only liked timelines for user' do
      user1 = create(:user, facebook_id: 'facebook-1')
      user2 = create(:user, facebook_id: 'facebook-2')
      user3 = create(:user, facebook_id: 'facebook-3')

      timeline1 = create(:timeline, user: user2)
      timeline2 = create(:timeline, user: user3)
      timeline3 = create(:timeline, user: user1)

      user1.like!(timeline1)
      likes = Likes.new(user1)
      likes.current_user = user1
      likes.params = {}

      timelines, _activities, _publishers = likes.timelines
      expect(timelines.size).to eq(1)
      expect(timelines).to include(timeline1)

      user1.like!(timeline2)
      likes = Likes.new(user1)
      likes.current_user = user1
      likes.params = {}

      timelines, _activities, _publishers = likes.timelines
      expect(timelines.size).to eq(2)
      expect(timelines).to include(timeline1)
      expect(timelines).to include(timeline2)

      user1.unlike!(timeline2)
      likes = Likes.new(user1)
      likes.current_user = user1
      likes.params = {}

      timelines, _activities, _publishers = likes.timelines
      expect(timelines.size).to eq(1)
      expect(timelines).to include(timeline1)
    end

    it 'should track is_liked by passed user' do
      user1 = create(:user, facebook_id: 'facebook-1')
      user2 = create(:user, facebook_id: 'facebook-2')
      user3 = create(:user, facebook_id: 'facebook-3')

      timeline1 = create(:timeline, user: user2)
      timeline2 = create(:timeline, user: user3)
      timeline3 = create(:timeline, user: user1)

      user1.like!(timeline1)
      user1.like!(timeline2)
      user2.like!(timeline1)
      user2.like!(timeline3)

      likes = Likes.new(user2)
      likes.current_user = user1
      likes.params = {}

      timelines, _activities, _publishers = likes.timelines
      expect(timelines.size).to eq(2)
      expect(timelines).to include(timeline1)
      expect(timelines).to include(timeline3)

      t1 = timelines.detect { |timeline| timeline.id == timeline1.id }
      expect(t1.is_liked).to eq(true)
      t2 = timelines.detect { |timeline| timeline.id == timeline3.id }
      expect(t2.is_liked).to eq(false)

      likes = Likes.new(user2)
      likes.current_user = user2
      likes.params = {}
      timelines, _activities, _publishers = likes.timelines

      expect(timelines.size).to eq(2)
      expect(timelines).to include(timeline1)
      expect(timelines).to include(timeline3)
      t1 = timelines.detect { |timeline| timeline.id == timeline1.id }
      expect(t1.is_liked).to eq(true)
      t2 = timelines.detect { |timeline| timeline.id == timeline3.id }
      expect(t2.is_liked).to eq(true)
    end

  end
end
