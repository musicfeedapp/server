require 'spec_helper'

describe AggregatorPublisher do

  it 'should create by attributes the new record' do
    expect(Timeline.count).to eq(0)

    user1 = create(:user, facebook_id: 'facebook-id1', username: 'zakharslabodnik')
    user2 = create(:user, facebook_id: 'facebook-id2', username: 'artemslabodnik')
    user3 = create(:user, facebook_id: 'facebook-id3', username: 'alexandrkorsak')
    user4 = create(:user, facebook_id: 'facebook-id4', user_type: 'artist', username: 'majesticcasual')

    timeline_attributes = attributes_for(:timeline)
    timeline_attributes.merge!(to: [user1.facebook_id])
    timeline_attributes.merge!(user_identifier: user3.facebook_id)
    timeline_attributes.merge!(artist_identifier: user4.facebook_id)

    response, timeline = AggregatorPublisher.publish(timeline_attributes)
    expect(response).to eq(true)

    expect(Timeline.count).to eq(1)
    expect(timeline.import_source).to eq('feed')

    publishers = timeline.publishers.to_a
    expect(publishers.size).to eq(3)

    collection = publishers.map(&:id)
    expect(collection).to include(user1.id)
    expect(collection).to include(user3.id)
    expect(collection).to include(user4.id)
  end

end

