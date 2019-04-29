require 'spec_helper'

describe User do

  describe '#friend!' do
    it 'should be possible to follow other users' do
      user1 = create(:user)
      user2 = create(:user)
      user3 = create(:user)

      user1.friend!(user2)
      user2.friend!(user3)

      expect(user1.reload.friends).to eq([user2])

      expect(user2.reload.friends).to include(user3)
      expect(user2.reload.friends).to include(user1)

      expect(user3.reload.friends).to eq([user2])
    end
  end

  it 'should destroy dependencices' do
    user1 = create(:user)
    user2 = create(:user)

    user1.friend!(user2)

    user1.destroy

    expect(UserFriend.count).to eq(0)
  end

end

