require 'spec_helper'

describe PublisherTimeline do
  it 'should allow to create one more timeline object newly created timeline object and user' do
    expect(Timeline.count).to eq(0)
    expect(Comment.count).to eq(0)

    user = create(:user, facebook_id: 'facebook-1')
    timeline = build(:timeline)

    response, timeline = PublisherTimeline.find_or_create_for(user, timeline)

    expect(response).to eq(true)
    expect(Timeline.count).to eq(1)
    expect(Comment.count).to eq(1)
  end

  it 'should never create duplicates for diff users and timelines' do
    expect(Timeline.count).to eq(0)
    expect(Comment.count).to eq(0)

    user1 = create(:user, facebook_id: 'facebook-1')
    user2 = create(:user, facebook_id: 'facebook-1')

    timeline = build(:timeline, youtube_link: 'http://www.example.com/1', source_link: 'http://www.example.com/1')
    response, timeline = PublisherTimeline.find_or_create_for(user1, timeline)
    expect(response).to eq(true)

    timeline = build(:timeline, youtube_link: 'http://www.example.com/1', source_link: 'http://www.example.com/1')
    response, timeline = PublisherTimeline.find_or_create_for(user2, timeline)
    expect(response).to eq(true)

    expect(Timeline.count).to eq(1)
    expect(Comment.count).to eq(2)
  end
end
