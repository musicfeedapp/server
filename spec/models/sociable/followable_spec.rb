require 'spec_helper'

describe User do

  describe '#follow!' do
    it 'should be possible to follow other users' do
      user1 = create(:user)
      user2 = create(:user)
      user3 = create(:user)

      user1.follow!(user2)
      user2.follow!(user3)

      expect(user3.reload.followers).to eq([user2])
      expect(user3.reload.followed.empty?).to eq(true)

      expect(user1.reload.followers.empty?).to eq(true)
      expect(user1.reload.followed).to eq([user2])

      expect(user2.reload.followers).to eq([user1])
      expect(user2.reload.followed).to eq([user3])
    end

    it 'should not create duplicates' do
      user1 = create(:user)
      user2 = create(:user)

      user1.follow!(user2)
      user1.reload
      user2.reload

      user1.follow!(user2)
      user1.reload
      user2.reload

      expect(user1.user_followers.count).to eq(0)
      expect(user1.user_followed.count).to eq(1)
      expect(user1.followed).to eq([user2])

      expect(user2.followers).to eq([user1])
      expect(user2.user_followed.count).to eq(0)
    end
  end

  describe '#unfollow!' do
    it 'should be possible to unfollow other users' do
      user1 = create(:user)
      user2 = create(:user)
      user3 = create(:user)

      user1.follow!(user2)
      user2.follow!(user3)

      user2.unfollow!(user3)

      expect(user1.reload.followers.to_a).to eq([])
      expect(user1.reload.followed.to_a).to eq([user2])

      expect(user2.reload.followers.to_a).to eq([user1])
      expect(user2.reload.followed.to_a).to eq([])

      expect(user3.reload.followers.to_a).to eq([])
      expect(user3.reload.followed.to_a).to eq([])

      user2.follow!(user3)

      expect(user1.reload.followers.to_a).to eq([])
      expect(user1.reload.followed.to_a).to eq([user2])

      expect(user2.reload.followers.to_a).to eq([user1])
      expect(user2.reload.followed.to_a).to eq([user3])

      expect(user3.reload.followers.to_a).to eq([user2])
      expect(user3.reload.followed.to_a).to eq([])
    end
  end

  it 'should destroy dependencices' do
    user1 = create(:user)
    user2 = create(:user)

    user1.follow!(user2)

    user1.destroy

    expect(UserFollower.count).to eq(0)
  end

end
