require 'spec_helper'

describe_client_api Api::Client::V1::Timelines do
  include UserMocks

  describe 'GET /timelines' do
    let!(:user) { create(:user, facebook_id: 'user-id-1') }

    before { logged_in(user) }

    let!(:timelines) { create_list(:timeline, 2, user: user) }

    it 'should have timeline routable path' do
      client_get 'timelines', authentication_token: user.authentication_token, email: user.email
      expect(response.status).not_to eq(404)
    end

    it 'should respond with bad request in case of the missing auth params' do
      client_get 'timelines', authentication_token: user.authentication_token
      expect(response.status).to eq(400)
      client_get 'timelines', email: user.email
      expect(response.status).to eq(400)
    end

    it 'should be successful on request with the valid credentials' do
      client_get 'timelines', authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(200)
    end

    it "should return list of the all user's timelines" do
      client_get 'timelines', authentication_token: user.authentication_token, email: user.email, facebook_user_id: user.facebook_id
      json_response do |json|
        expect(json).not_to be_empty

        json.each do |timeline|
          expect(timeline.keys).to include('id')
          expect(timeline.keys).to include('name')
          expect(timeline.keys).to include('link')
          expect(timeline.keys).to include('picture')
          expect(timeline.keys).to include('author')
          expect(timeline.keys).to include('user_identifier')
          expect(timeline.keys).to include('author_picture')
          expect(timeline.keys).to include('album')
          expect(timeline.keys).to include('artist')
          expect(timeline.keys).to include('likes_count')
          expect(timeline.keys).to include('published_at')
          expect(timeline.keys).to include('username')
          expect(timeline.keys).to include('font_color')
        end
      end
    end

    it 'should return the specific format for the published at date' do
      client_get 'timelines', authentication_token: user.authentication_token, email: user.email, facebook_user_id: user.facebook_id
      json_response do |json|
        published_ats = json.map {|timeline| timeline['published_at']}
        json.each do |timeline|
          expect(published_ats).to include(timelines[0].published_at.as_json) # 2014-04-15T11:20:59.903Z
          expect(published_ats).to include(timelines[1].published_at.as_json) # 2014-04-15T11:20:59.903Z
        end
      end
    end

    it 'includes is_liked node for timeline' do
      user.like!(timelines[0])
      user.unlike!(timelines[1])

      client_get 'timelines', authentication_token: user.authentication_token, email: user.email, facebook_user_id: user.facebook_id
      json_response do |json|
        timeline_attributes1 = json.find { |attributes| attributes['id'] == timelines[0].id }
        expect(timeline_attributes1['is_liked']).to eq(true)

        timeline_attributes2 = json.find { |attributes| attributes['id'] == timelines[1].id }
        expect(timeline_attributes2['is_liked']).to be_falsey
      end
    end

  end

  describe 'GET /timelines/youtube or spotify' do
    let!(:user) { create(:user, facebook_id: 'user-facebook-2') }

    before { logged_in(user) }

    let!(:youtube) { create(:youtube, user: user) }
    let!(:spotify) { create(:spotify, user: user) }

    it 'should have timeline routable path' do
      client_get 'timelines', feed_type: 'youtube', authentication_token: user.authentication_token, email: user.email
      expect(response.status).not_to eq(404)
      expect(response.status).not_to eq(400)

      client_get 'timelines', feed_type: 'spotify', authentication_token: user.authentication_token, email: user.email
      expect(response.status).not_to eq(404)
      expect(response.status).not_to eq(400)
    end

    it 'filters timelines by feed type' do
      client_get 'timelines', feed_type: 'youtube', authentication_token: user.authentication_token, email: user.email
      json_response do |json|
        expect(json).to have(1).item
        expect(json[0]['id']).to eq youtube.id
      end
    end

  end

  describe 'GET /timelines/timestamp and last_timeline_id' do
    let(:user_attributes) { { email: 'kate@example.com', authentication_token: 'auth-token', facebook_id: 'user-facebook-id-3' } }
    let!(:user) { create(:user, user_attributes) }

    before do
      allow(Timeline).to receive(:per_page).and_return(2)
    end

    before { logged_in(user) }

    it "returns list of the next timelines after passed timestamps and last timeline id" do
      timeline1 = create(:timeline, user: user, published_at: 0.day.ago, feed_type: 'youtube')
      timeline2 = create(:timeline, user: user, published_at: 1.day.ago, feed_type: 'youtube')
      timeline3 = create(:timeline, user: user, published_at: 2.day.ago, feed_type: 'youtube')
      timeline4 = create(:timeline, user: user, published_at: 3.day.ago, feed_type: 'youtube')
      timeline5 = create(:timeline, user: user, published_at: 4.day.ago, feed_type: 'youtube')
      timeline6 = create(:timeline, user: user, published_at: 5.day.ago, feed_type: 'youtube')

      client_get 'timelines', last_timeline_id: timeline3.id, timestamp: 0.days.ago, authentication_token: user.authentication_token, email: user.email
      json_response do |json|
        expect(json).to have(3).item
        timeline_ids = json.map { |timeline| timeline['id'] }
        expect(timeline_ids).to include(timeline4.id)
        expect(timeline_ids).to include(timeline5.id)
        expect(timeline_ids).to include(timeline6.id)
      end
    end

  end

  describe 'GET /timelines/exclude_feed_types' do
    let!(:user) { create(:user, facebook_id: 'user-facebook-44') }

    before do
      create(:spotify, user: user)
      create(:youtube, user: user)
      create(:soundcloud, user: user)
    end

    it 'returns list excluding passed types' do
      client_get 'timelines', authentication_token: user.authentication_token, email: user.email, exclude_feed_types: ['youtube', 'soundcloud']
      json_response do |json|
        expect(json).to have(1).item
        types = json.map { |timeline| timeline['feed_type'] }
        expect(types).to include('spotify')
      end
    end
  end

  describe 'GET /timelines/facebook_user_id' do
    let!(:kate) { create(:kate, facebook_id: 'facebook-id-1') }
    let!(:fred) { create(:fred, facebook_id: 'facebook-id-2') }
    let!(:user) { create(:user, facebook_id: 'facebook-id-3') }

    before { logged_in(user) }

    before do
      user.follow!(kate)
      user.follow!(fred)
    end

    it 'returns list filtered by facebook user id' do
      create(:timeline, user: kate)
      create(:timeline, user: user)
      create(:timeline, user: fred)

      client_get 'timelines', facebook_user_id: kate.facebook_id, authentication_token: user.authentication_token, email: user.email
      json_response do |json|
        expect(json).to have(1).item
        expect(json[0]['user_identifier']).to eq(kate.facebook_id)
      end

      client_get 'timelines', facebook_user_id: user.facebook_id, authentication_token: user.authentication_token, email: user.email
      json_response do |json|
        expect(json).to have(1).item
        expect(json[0]['user_identifier']).to eq(user.facebook_id)
      end
    end
  end


  describe 'GET /timelines/my' do
    let!(:kate) { create(:kate, facebook_id: 'facebook-id-kate') }
    let!(:user) { create(:user, facebook_id: 'facebook-id-user') }

    before { logged_in(user) }

    before do
      user.follow!(kate)

      create(:youtube, user: kate)
      create(:youtube, user: user)
      create(:youtube, user: user)
    end

    it 'returns list filtered by my music' do
      client_get 'timelines', my: true, authentication_token: user.authentication_token, email: user.email
      json_response do |json|
        expect(json).to have(2).items
        expect(json[0]['user_identifier']).to eq(user.facebook_id)
        expect(json[1]['user_identifier']).to eq(user.facebook_id)
      end
    end
  end

  describe 'GET /timelines/favourites columns' do
    let!(:user) { create(:user, facebook_id: 'facebook-id-1') }

    before { logged_in(user) }

    let(:favourite1) { create(:youtube, user: user) }
    let(:favourite2) { create(:youtube, user: user) }

    before do
      user.like!(favourite1)
      user.like!(favourite2)
    end

    it 'should mark favourite song in the list' do
      user.like!(favourite1)
      user.like!(favourite2)

      client_get 'timelines', authentication_token: user.authentication_token, email: user.email
      json_response do |json|
        expect(json).to have(2).items
        expect(json.find { |j| j['id'] == favourite1.id }['is_liked']).to be_truthy
        expect(json.find { |j| j['id'] == favourite2.id }['is_liked']).to be_truthy
      end

      user.unlike!(favourite2)
      client_get 'timelines', authentication_token: user.authentication_token, email: user.email
      json_response do |json|
        expect(json).to have(2).items
        expect(json.find { |j| j['id'] == favourite1.id }['is_liked']).to eq(true)
        expect(json.find { |j| j['id'] == favourite2.id }['is_liked']).to eq(false)
      end
    end

  end

  describe 'GET /timelines' do
    let!(:user) { create(:user, facebook_id: 'facebook-id-222') }

    before { logged_in(user) }

    it 'excludes timelines in case of deleted by this user' do
      timeline1 = create(:timeline, user: user)
      timeline2 = create(:timeline, user: user, restricted_users: [user.id])

      client_get 'timelines', authentication_token: user.authentication_token, email: user.email
      json_response do |json|
        expect(json).to have(1).item
        expect(json[0]['id']).not_to eq(timeline2.id)
      end
    end

  end

  describe 'DELETE /:id' do
    let!(:user) { create(:user, facebook_id: 'facebook-id-999') }

    before { logged_in(user) }

    let!(:timeline) { create(:timeline, user: user) }

    it 'deletes timeline item from the user feeds' do
      client_delete "timelines/#{timeline.id}", authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(200)
      expect(timeline.reload.restricted_users).to eq([user.id])
    end

    it 'should return number of removed tracks of owner of these tracks related to current user' do
      owner = create(:user, facebook_id: 'facebook-owner')
      timeline1 = create(:timeline, user: owner)
      timeline2 = create(:timeline, user: owner)
      timeline3 = create(:timeline, user: owner)
      timeline4 = create(:timeline, user: owner)

      # 3 times to remove feeds.
      client_delete "timelines/#{timeline1.id}", authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(200)
      expect(timeline1.reload.restricted_users.size).to eq(1)
      expect(timeline1.reload.restricted_users).to include(user.id)
      expect(JSON.parse(response.body)['unfollow']).to eq(false)

      client_delete "timelines/#{timeline2.id}", authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(200)
      expect(timeline2.reload.restricted_users.size).to eq(1)
      expect(timeline2.reload.restricted_users).to include(user.id)
      expect(JSON.parse(response.body)['unfollow']).to eq(false)

      client_delete "timelines/#{timeline3.id}", authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(200)
      expect(timeline3.reload.restricted_users.size).to eq(1)
      expect(timeline3.reload.restricted_users).to include(user.id)
      expect(JSON.parse(response.body)['unfollow']).to eq(true)

      expect(user.reload.restricted_users.size).to eq(3)

      # 2 times to decrease the number of removes
      client_post "timelines/removed/#{timeline1.id}/restore", authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(201)
      expect(user.reload.restricted_users.size).to eq(2)

      client_post "timelines/removed/#{timeline2.id}/restore", authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(201)
      expect(user.reload.restricted_users.size).to eq(1)

      client_delete "timelines/#{timeline2.id}", authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(200)
      expect(timeline2.reload.restricted_users.size).to eq(1)
      expect(timeline2.reload.restricted_users).to include(user.id)
      expect(JSON.parse(response.body)['unfollow']).to eq(false)
    end

    it 'should have order by removed time' do
      owner = create(:user, facebook_id: 'facebook-owner')

      timeline1 = create(:timeline, user: owner)
      timeline2 = create(:timeline, user: owner)
      timeline3 = create(:timeline, user: owner)

      # 3 times to remove feeds.
      client_delete "timelines/#{timeline2.id}", authentication_token: user.authentication_token, email: user.email
      client_delete "timelines/#{timeline1.id}", authentication_token: user.authentication_token, email: user.email
      client_delete "timelines/#{timeline3.id}", authentication_token: user.authentication_token, email: user.email

      client_get 'timelines/removed', authentication_token: user.authentication_token, email: user.email

      json_response do |json|
        expect(json.size).to eq(3)

        timeline_ids = json.map { |attributes| attributes['id'] }
        expect(timeline_ids[0]).to eq(timeline3.id)
        expect(timeline_ids[1]).to eq(timeline1.id)
        expect(timeline_ids[2]).to eq(timeline2.id)
      end
    end

    it 'should unlike post that was removed' do
      owner = create(:user, facebook_id: 'facebook-owner')
      timeline1 = create(:timeline, user: owner)

      client_put "timelines/#{timeline1.id}/like", authentication_token: user.authentication_token, email: user.email, id: timeline.id
      expect(response.status).to eq(200)
      expect(timeline1.reload.likes.to_a).to eq([user])

      client_delete "timelines/#{timeline1.id}", authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(200)
      expect(timeline1.reload.restricted_users.size).to eq(1)
      expect(timeline1.reload.restricted_users).to include(user.id)

      expect(timeline1.reload.likes.to_a.empty?).to eq(true)
      expect(JSON.parse(response.body)['unfollow']).to eq(false)
    end
  end

  describe 'PUT /like' do
    let!(:user) { create(:user, facebook_id: 'facebook-id-1') }

    before { logged_in(user) }

    it "likes timeline and don't make it multiple times" do
      timeline = create(:timeline, user: user)
      client_put "timelines/#{timeline.id}/like", authentication_token: user.authentication_token, email: user.email, id: timeline.id
      expect(response.status).to eq(200)
      expect(timeline.reload.likes.to_a).to eq([user])
    end

    it 'skip duplicates on many user heart requests' do
      timeline = create(:timeline, user: user)
      2.times { client_put "timelines/#{timeline.id}/like", authentication_token: user.authentication_token, email: user.email, id: timeline.id }
      expect(timeline.reload.likes.to_a).to eq([user])
    end
  end

  describe 'PUT /unlike' do
    let!(:user) { create(:user, facebook_id: 'facebook-id-10') }

    before { logged_in(user) }

    it "likes timeline and don't make it multiple times" do
      timeline = create(:timeline, user: user)

      user.like!(timeline)

      client_put "timelines/#{timeline.id}/unlike", authentication_token: user.authentication_token, email: user.email, id: timeline.id
      expect(response.status).to eq(200)
      expect(timeline.reload.likes.to_a).to be_empty
    end
  end

  describe 'GET /timelines/removed' do
    let!(:user) { create(:user) }

    before { logged_in(user) }

    let(:restrictions) { TimelineRestrictions.new(user) }

    it 'should be possible to get removed tracks for current user' do
      timeline1 = create(:timeline, user: user)
      timeline2 = create(:timeline, user: user)
      timeline3 = create(:timeline, user: user)

      restrictions.restrict!(timeline2)
      restrictions.restrict!(timeline3)

      client_get 'timelines/removed', authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(200)

      json_response do |json|
        expect(json.size).to eq(2)

        timeline_ids = json.map { |attributes| attributes['id'] }
        expect(timeline_ids).to include(timeline2.id)
        expect(timeline_ids).to include(timeline3.id)
      end
    end
  end

  describe 'POST /timelines/removed/:timeline_id/restore' do
    let!(:user) { create(:user) }

    before { logged_in(user) }

    let(:restrictions) { TimelineRestrictions.new(user) }

    it 'should be possible to restore removed timelines for current user' do
      timeline1 = create(:timeline, user: user)
      timeline2 = create(:timeline, user: user)
      timeline3 = create(:timeline, user: user)

      restrictions.restrict!(timeline2)
      restrictions.restrict!(timeline3)

      expect(timeline2.reload.restricted_users).to include(user.id)

      client_post "timelines/removed/#{timeline2.id}/restore", authentication_token: user.authentication_token, email: user.email
      expect(response.status).to eq(201)

      expect(timeline2.reload.restricted_users).not_to include(user.id)
    end
  end

end
