require 'spec_helper'

describe TimelinesCollection do

  it 'include favourites tracks of my followed users' do
    user1 = create(:user, name: 'user1', username: 'user1', facebook_id: 'id-1', facebook_profile_image_url: 'image1')
    user2 = create(:user, name: 'user2', username: 'user2', facebook_id: 'id-2', facebook_profile_image_url: 'image2')
    user3 = create(:user, name: 'user3', username: 'user3', facebook_id: 'id-3', facebook_profile_image_url: 'image3')
    user4 = create(:user, name: 'user4', username: 'user4', facebook_id: 'id-4', facebook_profile_image_url: 'image4')

    user1.follow!(user2)
    user2.follow!(user3)
    user3.follow!(user4)

    timeline1 = create(:timeline, user: user1)
    timeline2 = create(:timeline, user: user2)
    timeline3 = create(:timeline, user: user3)
    timeline4 = create(:timeline, user: user4)

    user2.like!(timeline3)

    timelines_collection = TimelinesCollection.new(user1)
    timelines, _a, _b = timelines_collection.find
    timelines = timelines.to_a

    expect(timelines).to have(2).items
    timeline_ids = timelines.map(&:id)
    expect(timeline_ids).to include(timeline1.id)
    expect(timeline_ids).to include(timeline2.id)
    # expect(timeline_ids).to include(timeline3.id)

    timelines_collection = TimelinesCollection.new(user2)
    timelines, _a, _b = timelines_collection.find
    timelines = timelines.to_a

    timeline_ids = timelines.map(&:id)
    expect(timeline_ids).to have(2).items
    expect(timeline_ids).to include(timeline2.id)
    expect(timeline_ids).to include(timeline3.id)

    timelines_collection = TimelinesCollection.new(user3)
    timelines, _a, _b = timelines_collection.find
    timelines = timelines.to_a

    expect(timelines).to have(2).items
    expect(timelines).to include(timeline3)
    expect(timelines).to include(timeline4)

    timelines_collection = TimelinesCollection.new(user4)
    timelines, _a, _b = timelines_collection.find
    timelines = timelines.to_a

    expect(timelines).to have(1).item
    expect(timelines).to include(timeline4)
  end

  it 'should properly show is_liked field' do
    user1 = create(:user, facebook_id: 'id-1')
    user2 = create(:user, facebook_id: 'id-2')

    user1.follow!(user2)

    timeline1 = create(:timeline, user: user1)
    timeline2 = create(:timeline, user: user2)

    user1.like!(timeline2)
    user2.like!(timeline1)

    timelines_collection = TimelinesCollection.new(user1)
    timelines, _a, _b = timelines_collection.find

    expect(timelines.to_a.size).to eq(2)
    timeline = timelines.find { |t| t.id == timeline1.id }
    expect(timeline.is_liked).to eq(false)
    timeline = timelines.find { |t| t.id == timeline2.id }
    expect(timeline.is_liked).to eq(true)

    timelines_collection = TimelinesCollection.new(user2)
    timelines, _a, _b = timelines_collection.find

    expect(timelines.to_a.size).to eq(1)
    timeline = timelines.find { |t| t.id == timeline2.id }
    expect(timeline.is_liked).to eq(false)
  end

  it 'should not have duplicates on timelines' do
    user1 = create(:user, facebook_id: 'id-1')
    user2 = create(:user, facebook_id: 'id-2')
    user3 = create(:user, facebook_id: 'id-3')

    user1.follow!(user2)

    timeline1 = create(:timeline, user: user1)
    timeline2 = create(:timeline, user: user2)
    timeline3 = create(:timeline, user: user3)

    user2.like!(timeline1)

    user2.follow!(user3)

    user2.like!(timeline3)
    user1.like!(timeline3)
    user3.like!(timeline3)

    user3.follow!(user2)
    user3.like!(timeline2)

    # @info user1 is not following user3 but he is still can like their posts
    # for showing in the feed.
    # user1.follow!(user3)

    timelines_collection = TimelinesCollection.new(user1)
    timelines, _a, _b = timelines_collection.find

    expect(timelines.to_a.size).to eq(2)
    expect(timelines).to include(timeline1)
    expect(timelines).to include(timeline2)
    # expect(timelines).to include(timeline3)
  end

  it 'should sort example1 depends on likes and published_at fields for timelines' do
    user1 = create(:user, facebook_id: 'id-1')
    user2 = create(:user, facebook_id: 'id-2')
    user3 = create(:user, facebook_id: 'id-3')
    user4 = create(:user, facebook_id: 'id-4')

    user1.follow!(user2)
    user2.follow!(user3)
    user3.follow!(user4)

    timeline1 = nil
    Timecop.travel(4.day.ago) do
      timeline1 = create(:timeline, user: user1, published_at: Date.today)
    end

    timeline2 = nil
    Timecop.travel(3.days.ago) do
      timeline2 = create(:timeline, user: user2, published_at: Date.today)
    end

    timeline3 = nil
    Timecop.travel(3.days.ago) do
      timeline3 = create(:timeline, user: user3, published_at: Date.today)
    end

    timeline4 = nil
    Timecop.travel(0.days.ago) do
      timeline4 = create(:timeline, user: user4, published_at: Date.today)
    end

    # timeline2, timeline1

    Timecop.travel(0.days.ago) do
      user1.like!(timeline2) # me liked the track, it should not go to the top
    end

    Timecop.travel(1.days.ago) do
      user2.like!(timeline3)
    end

    # timeline3(0), timeline2(3), timeline1(4)

    # skip this one on sorting because of no relation to friends of friends
    Timecop.travel(0.days.ago) do
      user3.like!(timeline2)
    end

    timelines_collection = TimelinesCollection.new(user1)
    timelines, _a, _b = timelines_collection.find
    timelines = timelines.to_a

    expect(timelines.size).to eq(2)
    # expect(timelines[0].id).to eq(timeline3.id)
    expect(timelines[1].id).to eq(timeline2.id)
    expect(timelines[2].id).to eq(timeline1.id)
  end

  it 'should sort example2 depends on likes and published_at fields for timelines' do
    user1 = create(:user, facebook_id: 'id-1')
    user2 = create(:user, facebook_id: 'id-2')
    user3 = create(:user, facebook_id: 'id-3')
    user4 = create(:user, facebook_id: 'id-4')

    user1.follow!(user2)
    user2.follow!(user3)
    user3.follow!(user4)

    timeline1 = nil
    Timecop.travel(1.day.ago) do
      timeline1 = create(:timeline, user: user1, published_at: Date.today)
    end

    timeline2 = nil
    Timecop.travel(2.days.ago) do
      timeline2 = create(:timeline, user: user2, published_at: Date.today)
    end

    timeline3 = nil
    Timecop.travel(3.days.ago) do
      timeline3 = create(:timeline, user: user3, published_at: Date.today)
    end

    timeline4 = nil
    Timecop.travel(4.days.ago) do
      timeline4 = create(:timeline, user: user4, published_at: Date.today)
    end

    Timecop.travel(3.days.ago) do
      user1.like!(timeline2)
    end

    Timecop.travel(0.days.ago) do
      user2.like!(timeline3)
    end

    # skip this one on sorting because of no relation to friends of friends
    Timecop.travel(0.days.ago) do
      user3.like!(timeline2)
    end

    timelines_collection = TimelinesCollection.new(user1)
    timelines, _a, _b = timelines_collection.find
    timelines = timelines.to_a

    expect(timelines.size).to eq(2)
    # expect(timelines[0].id).to eq(timeline3.id)
    expect(timelines[1].id).to eq(timeline1.id)
    expect(timelines[2].id).to eq(timeline2.id)
  end

  it 'should sort example3 depends on likes and published_at fields for timelines' do
    user1 = create(:user, facebook_id: 'id-1')
    user2 = create(:user, facebook_id: 'id-2')
    user3 = create(:user, facebook_id: 'id-3')
    user4 = create(:user, facebook_id: 'id-4')

    user1.follow!(user2)
    user2.follow!(user3)
    user3.follow!(user4)

    timeline1 = nil
    Timecop.travel(2.day.ago) do
      timeline1 = create(:timeline, user: user1, published_at: Date.today)
    end

    timeline2 = nil
    Timecop.travel(3.days.ago) do
      timeline2 = create(:timeline, user: user2, published_at: Date.today)
    end

    timeline3 = nil
    Timecop.travel(3.days.ago) do
      timeline3 = create(:timeline, user: user3, published_at: Date.today)
    end

    timeline4 = nil
    Timecop.travel(0.days.ago) do
      timeline4 = create(:timeline, user: user4, published_at: Date.today)
    end

    Timecop.travel(0.days.ago) do
      user1.like!(timeline2)
    end

    # 2(3), 3(1), 1(2)

    Timecop.travel(1.days.ago) do
      user2.like!(timeline3)
    end

    Timecop.travel(0.days.ago) do
      user2.like!(timeline1)
    end

    # skip this one on sorting because of no relation to friends of friends
    Timecop.travel(0.days.ago) do
      user3.like!(timeline2)
    end

    timelines_collection = TimelinesCollection.new(user1)
    timelines, _a, _b = timelines_collection.find
    timelines = timelines.to_a

    expect(timelines.size).to eq(2)
    # expect(timelines[0].id).to eq(timeline3.id)
    expect(timelines[1].id).to eq(timeline1.id)
    expect(timelines[2].id).to eq(timeline2.id)
  end

  it 'user should not see own liked posts on top of the list' do
    user1 = create(:user, facebook_id: 'id-1', is_verified: true)

    timeline1 = nil
    Timecop.travel(1.day.ago) do
      timeline1 = create(:timeline, user: user1)
    end

    timeline2 = nil
    Timecop.travel(2.days.ago) do
      timeline2 = create(:timeline, user: user1)
    end

    user1.like!(timeline2)

    # timeline1 - 1.day.ago
    # timeline2 - 2.days.ago

    timelines_collection = TimelinesCollection.new(user1)
    timelines, _a, _b = timelines_collection.find
    timelines = timelines.to_a

    expect(timelines.size).to eq(2)
    expect(timelines).to include(timeline1)
    expect(timelines).to include(timeline2)
  end

  it 'user should not see own activities on top of the list' do
    user1 = create(:user, facebook_id: 'id-1')
    user2 = create(:user, facebook_id: 'id-2')
    user3 = create(:user, facebook_id: 'id-3')

    timeline1 = nil
    Timecop.travel(1.day.ago) do
      timeline1 = create(:timeline, user: user1, published_at: Date.today)
    end

    timeline2 = nil
    Timecop.travel(2.days.ago) do
      timeline2 = create(:timeline, user: user2, published_at: Date.today)
    end

    timeline3 = nil
    Timecop.travel(3.day.ago) do
      timeline3 = create(:timeline, user: user1, published_at: Date.today)
    end

    timeline4 = nil
    Timecop.travel(4.day.ago) do
      timeline4 = create(:timeline, user: user2, published_at: Date.today)
    end

    timeline5 = nil
    Timecop.travel(5.day.ago) do
      timeline5 = create(:timeline, user: user3, published_at: Date.today) # 5
    end

    user1.follow!(user2)
    user2.follow!(user3)

    Timecop.travel(1.minute.ago) do
      user1.like!(timeline2)         # 1
    end

    Timecop.travel(2.minute.ago) do
      user2.like!(timeline3)         # 2
    end

    Timecop.travel(0.minute.ago) do
      user3.like!(timeline1)         # 4
    end

    Timecop.travel(4.minute.ago) do
      user2.like!(timeline5)         # 3
    end

    # timeline1 - 1.day.ago
    # timeline2 - 2.days.ago
    # timeline3 - 3.days.ago
    # timeline4 - 4.days.ago
    # timeline5 - 4.minutes.ago

    timelines_collection = TimelinesCollection.new(user1)
    timelines, _a, _b = timelines_collection.find
    timelines = timelines.to_a

    expect(timelines.size).to eq(4)
    # expect(timelines[0].id).to eq(timeline5.id)
    expect(timelines[1].id).to eq(timeline1.id)
    expect(timelines[2].id).to eq(timeline2.id)
    expect(timelines[3].id).to eq(timeline3.id)
    expect(timelines[4].id).to eq(timeline4.id)
  end


  it 'user should see followed users liked tracks on top of the list' do
    user1 = create(:user, facebook_id: 'id-1')
    user2 = create(:user, facebook_id: 'id-2')
    user3 = create(:user, facebook_id: 'id-3')

    timeline1 = nil
    Timecop.travel(1.day.ago) do
      timeline1 = create(:timeline, user: user2)
    end

    timeline2 = nil
    Timecop.travel(2.days.ago) do
      timeline2 = create(:timeline, user: user3)
    end

    user1.follow!(user2)
    user2.like!(timeline2)

    # timeline1 - 1.day.ago
    # timeline2 - 2.days.ago
    # timeline3 - 3.days.ago
    # timeline4 - 4.days.ago

    timelines_collection = TimelinesCollection.new(user1)
    timelines, _a, _b = timelines_collection.find
    timelines = timelines.to_a

    expect(timelines.size).to eq(2)
    expect(timelines[0]).to eq(timeline2)
    expect(timelines[1]).to eq(timeline1)
  end

  # it 'should track author_is_followed' do
  #   user1 = create(:user, facebook_id: 'id-1')
  #   user2 = create(:user, facebook_id: 'id-2')
  #   user3 = create(:user, facebook_id: 'id-3')
  #   user4 = create(:user, facebook_id: 'id-4')

  #   user1.follow!(user2)
  #   user2.follow!(user3)
  #   user3.follow!(user4)

  #   timeline1 = create(:timeline, user: user1)
  #   timeline2 = create(:timeline, user: user2)
  #   timeline3 = create(:timeline, user: user3)

  #   user1.like!(timeline2)
  #   user1.like!(timeline3)
  #   user2.like!(timeline3)

  #   timelines_collection = TimelinesCollection.new(user1)
  #   timelines = timelines_collection.find

  #   expect(timelines.to_a.size).to eq(3)

  #   timeline = timelines.find { |t| t.id == timeline1.id }

  #   expect(timeline.author_is_followed).to eq(false) # showed as user2

  #   timeline = timelines.find { |t| t.id == timeline2.id }
  #   expect(timeline.author_is_followed).to eq(true) # showed as user2

  #   timeline = timelines.find { |t| t.id == timeline3.id }
  #   expect(timeline.author_is_followed).to eq(false) # showed as user3
  # end

  it 'should have liked feeds of the friends' do
    user1 = create(:user, facebook_id: 'id-1')
    user2 = create(:user, facebook_id: 'id-2')
    user3 = create(:user, facebook_id: 'id-3')
    user4 = create(:user, facebook_id: 'id-4')

    user1.follow!(user2)

    timeline1 = create(:timeline, user: user1)
    timeline2 = create(:timeline, user: user2)
    timeline3 = create(:timeline, user: user3)
    timeline4 = create(:timeline, user: user4)

    user1.like!(timeline2)
    user1.like!(timeline3)
    user2.like!(timeline4)

    timelines_collection = TimelinesCollection.new(user1)
    timelines, _a, _b = timelines_collection.find
    timelines = timelines.to_a.map(&:id)

    # we are not including own liked posts
    expect(timelines).to include(timeline1.id)
    expect(timelines).to include(timeline2.id)
    # expect(timelines).to include(timeline4.id)
    expect(timelines.size).to eq(2)

    # lets include own posts because of user2 liked it as well
    user2.like!(timeline3)

    timelines_collection = TimelinesCollection.new(user1)
    timelines, _a, _b = timelines_collection.find
    timelines = timelines.to_a.map(&:id)

    expect(timelines).to include(timeline1.id)
    expect(timelines).to include(timeline2.id)
    # expect(timelines).to include(timeline3.id)
    # expect(timelines).to include(timeline4.id)
    expect(timelines.size).to eq(2)
  end

  it 'should respond with timeline where user is not original owner but he is awesome publisher' do
    user1 = create(:user, facebook_id: 'id-1')
    user2 = create(:user, facebook_id: 'id-2')
    user3 = create(:user, facebook_id: 'id-3')
    user4 = create(:user, facebook_id: 'id-4')

    timeline1 = nil
    Timecop.travel(1.days.ago) do
      timeline1 = create(:timeline, user: user1, published_at: DateTime.now.utc)
    end

    timeline2 = nil
    Timecop.travel(2.days.ago) do
      timeline2 = create(:timeline, user: user2, published_at: DateTime.now.utc)
    end

    timeline3 = nil
    Timecop.travel(3.days.ago) do
      timeline3 = create(:timeline, user: user2, published_at: DateTime.now.utc)
    end

    timeline4 = nil
    Timecop.travel(4.days.ago) do
      timeline4 = create(:timeline, user: user4, published_at: DateTime.now.utc)
    end

    user1.follow!(user3)

    timeline3.timeline_publishers.create!(user: user3)
    timeline4.timeline_publishers.create!(user: user1)

    timelines_collection = TimelinesCollection.new(user1)
    timelines, _a, _b = timelines_collection.find

    expect(timelines.to_a.size).to eq(3)
    expect(timelines).to include(timeline1)
    expect(timelines).to include(timeline3)
    expect(timelines).to include(timeline4)
  end

  it 'should show user repost on top of list' do
    user1 = create(:user, facebook_id: 'id-1')
    user2 = create(:user, facebook_id: 'id-2')

    timeline1 = nil
    Timecop.travel(1.days.ago) do
      timeline1 = create(:timeline, user: user1, published_at: DateTime.now.utc)
    end

    timeline2 = nil
    Timecop.travel(2.days.ago) do
      timeline2 = create(:timeline, user: user2, published_at: DateTime.now.utc)
    end

    user1.follow!(user2)

    # emulate repost activity
    success, _timeline = PublisherTimeline.find_or_create_for(user1, timeline2, disable_playlist_event: false, eventable_id: :reposted)
    expect(success).to eq(true)

    timelines_collection = TimelinesCollection.new(user1)
    timelines, _a, _b = timelines_collection.find

    expect(timelines.to_a.size).to eq(2)
    expect(timelines[0].id).to eq(timeline2.id)
    expect(timelines[1].id).to eq(timeline1.id)
  end
end
