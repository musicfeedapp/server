require 'spec_helper'

describe UserAdataper do
  describe '#user_followers' do
    it 'should sort by songs count, names and is_followed flag' do
      user1 = create(:user, name: "user1", facebook_id: 'facebook-id1')
      1.times { create(:timeline, user: user1) }

      user2 = create(:user, name: "user2", facebook_id: 'facebook-id2')
      3.times { create(:timeline, user: user2) }

      user3 = create(:user, name: "buser3", facebook_id: 'facebook-id3')
      2.times { create(:timeline, user: user3) }

      user4 = create(:user, name: "auser3", facebook_id: 'facebook-id4')
      5.times { create(:timeline, user: user4) }

      user5 = create(:user, name: "cuser3", facebook_id: 'facebook-id5')
      4.times { create(:timeline, user: user5) }

      user6 = create(:user, name: "user6", facebook_id: 'facebook-id6')
      2.times { create(:timeline, user: user6) }

      user = create(:user, facebook_id: 'facebook-id-x')

      user1.follow!(user)
      user2.follow!(user)
      user3.follow!(user)
      user4.follow!(user)
      user5.follow!(user)

      user.follow!(user1)

      current_user = user
      for_user = user

      service = UserAdataper.new(current_user, for_user)
      followers = service.user_followers.to_a

      expect(followers).to have(5).items

      expect(followers[0].id).to eq(user1.id)
      expect(followers[1].id).to eq(user4.id)
      expect(followers[2].id).to eq(user5.id)
      expect(followers[3].id).to eq(user2.id)
      expect(followers[4].id).to eq(user3.id)
    end
  end

  describe '#user_followings' do
    it 'should sort by songs count, names and is_followed flag' do
      user1 = create(:user, name: "user1", facebook_id: 'facebook-id1')
      1.times { create(:timeline, user: user1) }

      user2 = create(:user, name: "user2", facebook_id: 'facebook-id2')
      3.times { create(:timeline, user: user2) }

      user3 = create(:user, name: "buser3", facebook_id: 'facebook-id3')
      2.times { create(:timeline, user: user3) }

      user4 = create(:user, name: "auser3", facebook_id: 'facebook-id4')
      5.times { create(:timeline, user: user4) }

      user5 = create(:user, name: "cuser3", facebook_id: 'facebook-id5')
      4.times { create(:timeline, user: user5) }

      user6 = create(:user, name: "user6", facebook_id: 'facebook-id6')
      2.times { create(:timeline, user: user6) }

      user = create(:user, facebook_id: 'facebook-id6')

      user.follow!(user1)
      user.follow!(user2)
      user.follow!(user3)
      user.follow!(user4)
      user.follow!(user5)

      # user1 - 1
      # user2 - 3
      # user3 - 2
      # user4 - 5
      # user5 - 4
      # user6 - 2 -

      service = UserAdataper.new(user, user)
      followings = service.user_followings

      expect(followings).to have(5).items
      expect(followings[0].id).to eq(user4.id)
      expect(followings[1].id).to eq(user5.id)
      expect(followings[2].id).to eq(user2.id)
      expect(followings[3].id).to eq(user3.id)
      expect(followings[4].id).to eq(user1.id)
    end

    it 'should deal with friends as same as followers' do
      user1 = create(:user, name: "user1", facebook_id: 'facebook-id1')
      1.times { create(:timeline, user: user1) }

      user2 = create(:user, name: "user2", facebook_id: 'facebook-id2')
      3.times { create(:timeline, user: user2) }

      user3 = create(:user, name: "buser3", facebook_id: 'facebook-id3')
      2.times { create(:timeline, user: user3) }

      user4 = create(:user, name: "auser3", facebook_id: 'facebook-id4')
      5.times { create(:timeline, user: user4) }

      user5 = create(:user, name: "cuser3", facebook_id: 'facebook-id5')
      4.times { create(:timeline, user: user5) }

      user6 = create(:user, name: "user6", facebook_id: 'facebook-id6')
      2.times { create(:timeline, user: user6) }

      user = create(:user, facebook_id: 'facebook-id6')

      user.friend!(user1)
      user.follow!(user1)
      user.friend!(user2)

      service = UserAdataper.new(user, user)
      followings = service.user_followings

      expect(followings).to have(1).items
      expect(followings[0].id).to eq(user1.id)
      expect(followings).not_to include(user2)
    end

    it "should only return those users where 'is_followed' is not true" do
      user1 = create(:user, name: "user1", facebook_id: 'facebook-id1')
      user2 = create(:user, name: "user2", facebook_id: 'facebook-id2')

      user = create(:user, facebook_id: 'facebook-id')

      user1.follow!(user)
      user1.friend!(user)

      user.follow!(user2)

      service = UserAdataper.new(user, user)
      followings = service.user_followings

      expect(followings).to have(1).item
      expect(followings[0].id).to eq(user2.id)

      # user1 will not be included as they are just friends but haven't followed
      expect(followings).not_to include(user1)
    end
  end

  describe '#songs' do
    context "when user type is user" do
      it 'should returns user songs and liked' do
        user1 = create(:user, facebook_id: 'facebook-id1')
        timeline1 = create(:timeline, user: user1)

        user2 = create(:user, facebook_id: 'facebook-id2')
        timeline2 = create(:timeline, user: user2)
        timeline3 = create(:timeline, user: user2)

        user2.like!(timeline1.id)
        user1.like!(timeline2.id)

        service = UserAdataper.new(user1, user1)
        timelines, _activities, _publishers = service.songs

        expect(timelines).to have(2).items
        expect(timelines).to include(timeline1)
        expect(timelines).to include(timeline2)

        expect(service.songs_count).to eq(2)
      end
    end

    context "when user type is artist" do
      it "should only returns artist songs" do
        user     = create(:user, facebook_id: 'facebook-id1')
        artist   = create(:user, user_type: 'artist', facebook_id: 'facebook-id2')

        timeline1 = create(:timeline, user: artist)
        timeline2 = create(:timeline, user: user)

        service = UserAdataper.new(user, artist)
        timelines, _activities, _publishers = service.songs

        expect(timelines).to have(1).items
        expect(timelines).to include(timeline1)
        expect(timelines).to_not include(timeline2)

        expect(service.songs_count).to eq(1)
      end
    end
  end
end
