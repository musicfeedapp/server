require 'spec_helper'

describe Facebook::Proposals do

  describe '.find!' do
    it 'automatically creates followings for user' do
      user = create(:user)

      allow_any_instance_of(Facebook::Proposals::Maker).to receive(:collection).and_return(
        friends: [
          {"name"=>"Kozlovsky Dmitry", "id" => "1", "is_verified" => "true" }
        ],
        artists: [
          {"category"=>"Musician/band", "name"=>"MODESTEP", "created_time"=>"2012-04-08T18:33:08+0000", "id"=> '3', "is_verified" => "true"}
        ],
      )

      proposals = Facebook::Proposals::Maker.new(user, new_user: true)
      proposals.find!

      user.reload

      expect(user.friends.to_a).to have(1).items
      expect(user.followed.to_a).to have(2).items

      friend = user.followed.detect { |f| f.user_type == 'user' }
      artist = user.followed.detect { |f| f.user_type == 'artist' }

      expect(friend.user_type).to eq('user')
      expect(friend.name).to be
      expect(friend.username).to be
      expect(friend.profile_image).to be
      expect(friend.facebook_link).to eq('https://www.facebook.com/1')

      expect(artist.user_type).to eq('artist')
      expect(artist.name).to be
      expect(artist.username).to be
      expect(artist.profile_image).to be
      expect(artist.facebook_link).to eq('https://www.facebook.com/3')
      expect(artist.category).to eq('Musician/band')
    end

    it 'creates once based on got it facebook ids' do
      user = create(:user, facebook_id: 'better-facebook-id')

      user1 = create(:user, facebook_id: 'id-1')
      user2 = create(:user, facebook_id: 'id-2')
      user3 = create(:user, facebook_id: 'id-3')

      user.friend!(user1)
      user.friend!(user2)

      user.follow!(user2)

      allow_any_instance_of(Facebook::Proposals::Maker).to receive(:collection).and_return(
        friends: [
          {"name"=>user1.name, "id" => user1.facebook_id, "is_verified" => "true"},
          {"name"=>user2.name, "id" => user2.facebook_id, "is_verified" => "true"},
          {"name"=>'User 3', "id" => 'id-3', "is_verified" => "true"},
          {"name"=>'User 4', "id" => 'id-4', "is_verified" => "true"},
        ],
        artists: [
          {"category"=>"Musician/band", "name"=>"MODESTEP", "created_time"=>"2012-04-08T18:33:08+0000", "id"=> 'id-modestep', "is_verified" => "true"},
        ])

      # @note should work fine on multiple calls on friends and artists creation.
      2.times do
        proposals = Facebook::Proposals::Maker.new(user)
        proposals.find!
      end

      expect(User.count).to eq([user, user1, user2, user3, 'User 3', 'band'].size)

      user.reload

      expect(user.friends.to_a).to have(4).items
      expect(user.followed.to_a).to have(2).items

      expect(user.friends_count).to eq(4)
      expect(user.followed_count).to eq(2)
      expect(user.followers_count).to eq(0)

      artist = User.artist.where(facebook_id: 'id-modestep').first
      expect(artist.category).to eq('Musician/band')
      expect(artist.created_at).to be
    end
  end

end
