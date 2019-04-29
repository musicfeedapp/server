require 'spec_helper'
require 'sidekiq/testing'

describe Facebook::Proposals::Followers do
  before { Facebook::Feed::ArtistWorker.jobs.clear }

  let(:user) { create(:user) }

  describe "#create" do
    let(:artists) { [{ "id" => "171989820489980", "name" => "FooBar", "is_verified" => true, "category" => "People/Comedian" }] }

    let(:artists_facebook_ids) { ["471989820489980", "271989820489980", "371989820489980"] }
    let(:allowed_facebook_ids) { ["171989820489980"] }

    subject { Facebook::Proposals::Followers.create(user, artists, artists_facebook_ids, allowed_facebook_ids, {}) }

    it "should automatically add new job for ArtistAggregatorWorker" do
      expect { subject }.to change{ Facebook::Feed::ArtistWorker.jobs.count }.from(0).to(1)
    end

    it "should not re-follow the unfollowed user when fetched from facebook" do
      user = create(:user)

      user1 = create(:user, facebook_id: "471989820489980")
      user2 = create(:user, facebook_id: "271989820489980", user_type: "artist")
      user3 = create(:user, facebook_id: "371989820489980", user_type: "artist")

      user.friend!(user1)

      user.follow!(user2)
      user.follow!(user3)

      user.unfollow!(user3)

      subject

      expect(user.followed).not_to include(user3)
      expect(user.followed.count).to eq(1)
    end
  end
end
