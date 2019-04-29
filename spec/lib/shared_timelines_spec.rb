require 'spec_helper'

describe TimelinesCollection do
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
    Timecop.travel(1.days.ago) do
      timeline2 = create(:timeline, user: user2, published_at: DateTime.now.utc)
    end

    timeline3 = nil
    Timecop.travel(1.days.ago) do
      timeline3 = create(:timeline, user: user3, published_at: DateTime.now.utc)
    end

    timeline4 = nil
    Timecop.travel(1.days.ago) do
      timeline4 = create(:timeline, user: user4, published_at: DateTime.now.utc)
    end

    user1.follow!(user2)
    user1.follow!(user3)
    user1.follow!(user4)

    timeline2.timeline_publishers.create!(user: user3)
    timeline2.timeline_publishers.create!(user: user4)

    timeline3.timeline_publishers.create!(user: user1)
    timeline3.timeline_publishers.create!(user: user2)
    timeline3.timeline_publishers.create!(user: user4)

    timeline4.timeline_publishers.create!(user: user3)

    timelines_collection = TimelinesCollection.new(user1)
    timelines, _a, _b = timelines_collection.find_by_shared

    expect(timelines.to_a.size).to eq(4)
    expect(timelines[0].id).to eq(timeline3.id)
    expect(timelines[1].id).to eq(timeline2.id)
    expect(timelines[2].id).to eq(timeline4.id)
    expect(timelines[3].id).to eq(timeline1.id)
  end
end
