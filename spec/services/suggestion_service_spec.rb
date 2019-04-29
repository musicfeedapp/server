require 'spec_helper'

describe SuggestionsService do
  let(:user) { create(:user, facebook_id: 'facebook-0') }
  let(:service) { SuggestionsService.new(user) }

  it 'should picks top 100 artists from the database based on followed number of the users' do
    artist1 = create(:artist, facebook_id: 'facebook-1')
    11.times { create(:timeline, user: artist1) }

    artist2 = create(:artist, facebook_id: 'facebook-2')
    11.times { create(:timeline, user: artist2) }

    artist3 = create(:artist, facebook_id: 'facebook-3')
    11.times { create(:timeline, user: artist3) }

    artist4 = create(:artist, facebook_id: 'facebook-4')
    11.times { create(:timeline, user: artist4) }

    artist5 = create(:artist, facebook_id: 'facebook-5')
    11.times { create(:timeline, user: artist5) }

    user1 = create(:user)
    user2 = create(:user)
    user3 = create(:user)
    user4 = create(:user)
    user5 = create(:user)

    user1.follow!(artist1)
    user2.follow!(artist1)

    user1.follow!(artist2)

    user1.follow!(artist3)
    user3.follow!(artist3)
    user4.follow!(artist3)

    user1.follow!(artist5)
    user2.follow!(artist5)
    user3.follow!(artist5)
    user4.follow!(artist5)

    user1.follow!(artist4)
    user2.follow!(artist4)
    user3.follow!(artist4)
    user4.follow!(artist4)
    user5.follow!(artist4)

    Suggestions.refresh

    collection = service.artists.to_a
    expect(collection.size).to eq(5)
    expect(collection[0]).to eq(artist4)
    expect(collection[1]).to eq(artist5)
    expect(collection[2]).to eq(artist3)
    expect(collection[3]).to eq(artist1)
    expect(collection[4]).to eq(artist2)
  end

  it 'should skip followed users' do
    artist1 = create(:artist, facebook_id: 'facebook-1')
    11.times { create(:timeline, user: artist1) }

    artist2 = create(:artist, facebook_id: 'facebook-2')
    11.times { create(:timeline, user: artist2) }

    user1 = create(:user, facebook_id: 'facebook-3')
    user2 = create(:user, facebook_id: 'facebook-4')

    user1.follow!(artist1)
    user2.follow!(artist2)

    # this user should be skipped because of having it in the followings list.
    user.follow!(artist1)

    user.follow!(user1)
    user.follow!(user2)

    service = SuggestionsService.new(user.reload)

    Suggestions.refresh

    collection = service.artists.to_a
    expect(collection.size).to eq(1)
    expect(collection[0]).to eq(artist2)
  end

  it 'finds only 3 latest feeds for suggestions for each artist' do
    artist1 = create(:artist, facebook_id: 'facebook-1')
    11.times { create(:timeline, user: artist1) }

    artist2 = create(:artist, facebook_id: 'facebook-2')
    11.times { create(:timeline, user: artist2) }

    Suggestions.refresh

    timelines, _activities, _publishers = service.timelines

    expect(timelines[artist1.id].size).to eq(6)
    expect(timelines[artist2.id].size).to eq(6)
  end

  it 'should have the artists which have been followed the most number of times in the last 30 days' do
    user2 = create(:user)

    artist1 = create(:artist, facebook_id: 'facebook-1')
    artist2 = create(:artist, facebook_id: 'facebook-2')
    artist3 = create(:artist, facebook_id: 'facebook-3')
    artist4 = create(:artist, facebook_id: 'facebook-4')

    user2.follow!(artist1)
    user2.follow!(artist2)
    user2.follow!(artist3).update_attribute(:created_at, DateTime.now - 60.days)

    Suggestions.refresh

    trending_artists = service.trending_artists
    expect(trending_artists.size).to eq(2)
    expect(trending_artists).not_to include(artist3)
    expect(trending_artists).not_to include(artist4)
  end

  it 'should return common followers for suggested artists' do
    user1 = create(:user, facebook_id: 'facebook-1')
    user2 = create(:user, facebook_id: 'facebook-2')
    user3 = create(:user, facebook_id: 'facebook-3')

    artist1 = create(:artist, facebook_id: 'facebook-1')
    artist2 = create(:artist, facebook_id: 'facebook-2')
    artist3 = create(:artist, facebook_id: 'facebook-3')

    user.follow!(user1)
    user.follow!(user3)
    user.follow!(artist1)

    user1.follow!(artist1)
    user2.follow!(artist1)
    user3.follow!(artist1)

    user1.follow!(artist2)
    user2.follow!(artist2)

    user1.follow!(artist3)
    user3.follow!(artist3)

    artist1.follow!(artist2)
    artist1.follow!(artist3)

    Suggestions.refresh

    collection = service.common_followers([artist1, artist2, artist3])

    expect(collection[artist1.id]).to include(user1)
    expect(collection[artist1.id]).not_to include(user2)
    expect(collection[artist1.id]).to include(user3)

    expect(collection[artist2.id]).to include(user1)
    expect(collection[artist2.id]).not_to include(user2)
    expect(collection[artist2.id]).not_to include(user3)

    expect(collection[artist2.id]).to include(artist1)
    expect(collection[artist3.id]).to include(artist1)

    expect(collection[artist3.id]).to include(user1)
    expect(collection[artist3.id]).not_to include(user2)
    expect(collection[artist3.id]).to include(user3)
  end
end
