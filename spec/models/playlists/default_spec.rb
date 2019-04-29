require 'spec_helper'

module Playlists
  describe Default do
    let(:params) { {} }

    it 'should not returns liked and return only own timelines for user' do
      user1 = create(:user, facebook_id: 'facebook-1')
      user2 = create(:user, facebook_id: 'facebook-2')
      user3 = create(:user, facebook_id: 'facebook-3')

      timeline1 = create(:timeline, user: user2)
      timeline2 = create(:timeline, user: user3)
      timeline3 = create(:timeline, user: user1)

      default = Default.new(user1)
      default.current_user = user1
      default.params = params
      timelines, _activities, _publishers = default.timelines
      expect(timelines.to_a.size).to eq(1)
      expect(timelines).not_to include(timeline1)
      expect(timelines).not_to include(timeline2)
      expect(timelines).to include(timeline3)

      user1.like!(timeline1)
      default = Default.new(user1)
      default.current_user = user1
      default.params = params
      timelines, _activities, _publishers = default.timelines

      expect(timelines.to_a.size).to eq(1)
      expect(timelines).not_to include(timeline1)
      expect(timelines).not_to include(timeline2)
      expect(timelines).to include(timeline3)

      user1.like!(timeline2)
      default = Default.new(user1)
      default.current_user = user1
      default.params = params
      timelines, _activities, _publishers = default.timelines
      expect(timelines.to_a.size).to eq(1)
      expect(timelines).not_to include(timeline1)
      expect(timelines).not_to include(timeline2)
      expect(timelines).to include(timeline3)

      user1.unlike!(timeline2)
      default = Default.new(user1)
      default.current_user = user1
      default.params = params
      timelines, _activities, _publishers = default.timelines
      expect(timelines.to_a.size).to eq(1)
      expect(timelines).not_to include(timeline1)
      expect(timelines).not_to include(timeline2)
      expect(timelines).to include(timeline3)

      user1.follow!(user2)
      default = Default.new(user1)
      default.current_user = user1
      default.params = params
      timelines, _activities, _publishers = default.timelines
      expect(timelines.to_a.size).to eq(1)
      expect(timelines).not_to include(timeline1)
      expect(timelines).not_to include(timeline2)
      expect(timelines).to include(timeline3)
    end

    it 'should be possible to add / remove timeline' do
      user1 = create(:user, facebook_id: 'facebook-1')
      user2 = create(:user, facebook_id: 'facebook-2')
      user3 = create(:user, facebook_id: 'facebook-3')

      timeline1 = create(:timeline, user: user2)
      timeline2 = create(:timeline, user: user3)
      timeline3 = create(:timeline, user: user1)

      default = Default.new(user1)
      default.current_user = user1
      default.params = params
      default.add_timeline(timeline2.id)

      default = Default.new(user1)
      default.current_user = user1
      default.params = params
      timelines, _activities, _publishers = default.timelines
      expect(timelines.to_a.size).to eq(1)
      expect(timelines).not_to include(timeline1)
      expect(timelines).not_to include(timeline2)
      expect(timelines).to include(timeline3)

      default = Default.new(user1)
      default.current_user = user1
      default.params = params
      default.remove_timeline(timeline2.id)

      default = Default.new(user1)
      default.current_user = user1
      default.params = params
      timelines, _activities, _publishers = default.timelines
      expect(timelines.to_a.size).to eq(1)
      expect(timelines).not_to include(timeline1)
      expect(timelines).not_to include(timeline2)
      expect(timelines).to include(timeline3)
    end

  end
end
