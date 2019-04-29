require 'spec_helper'

describe Likeable do
  let(:user) { create(:user) }

  it 'should be possible to get likes' do
    timeline1 = create(:timeline, user: user)
    timeline1.activities.destroy_all

    timeline2 = create(:timeline, user: user)
    timeline2.activities.destroy_all

    user = create(:user, facebook_id: 'facebook-id-1')

    user.like!(timeline2.id)
    expect(user.reload.likes.count).to eq(1)
    expect(user.likes).to include(timeline2)
    expect(user.likes_count).to eq(1)

    user.like!(timeline1.id)
    expect(user.reload.likes.count).to eq(2)
    expect(user.likes_count).to eq(2)
    expect(user.likes).to include(timeline1)
    expect(user.likes).to include(timeline2)
  end

  it 'should be possible to pass object instead of id' do
    timeline1 = create(:timeline, user: user)
    timeline1.activities.destroy_all

    timeline2 = create(:timeline, user: user)
    timeline2.activities.destroy_all

    user = create(:user, facebook_id: 'facebook-id-1')

    user.like!(timeline2.id)
    expect(user.reload.likes.count).to eq(1)
    expect(user.likes).to include(timeline2)

    user.like!(timeline1.id)
    expect(user.reload.likes.count).to eq(2)
    expect(user.likes).to include(timeline1)
    expect(user.likes).to include(timeline2)

    user.unlike!(timeline1)
    expect(user.reload.likes.count).to eq(1)
    expect(user.likes).to include(timeline2)

    user.like!(timeline2)
    expect(user.reload.likes.count).to eq(1)
    expect(user.likes).to include(timeline2)

    user.like!(timeline1)
    expect(user.reload.likes.count).to eq(2)
    expect(user.likes).to include(timeline1)
    expect(user.likes).to include(timeline2)
  end

  it 'should update likes_count for timeline as well' do
    timeline1 = create(:timeline, user: user)
    timeline1.activities.destroy_all

    timeline2 = create(:timeline, user: user)
    timeline2.activities.destroy_all

    user1 = create(:user)
    user2 = create(:user)

    user1.like!(timeline1)
    user1.like!(timeline2)

    user2.like!(timeline2)

    expect(user1.reload.likes_count).to eq(2)
    expect(user2.reload.likes_count).to eq(1)

    expect(timeline1.reload.likes_count).to eq(1)
    expect(timeline2.reload.likes_count).to eq(2)
  end

  it 'should create comment with event_type = "like"' do
    timeline1 = create(:timeline, user: user)
    timeline1.activities.destroy_all

    user1 = create(:user)
    user2 = create(:user)

    user_like = user1.like!(timeline1)
    expect(user_like.comment).to be
    comments = timeline1.reload.activities.to_a

    expect(comments.size).to eq(1)
    expect(comments[0].comment).to eq(user1.name)
    expect(comments[0].eventable_id).to eq(user_like.id.to_s)
    expect(comments[0].eventable_type).to eq(user_like.class.name)

    user_like = user2.like!(timeline1)
    expect(user_like.comment).to be

    comments = timeline1.reload.activities.to_a
    expect(comments.size).to eq(2)

    comment = user_like.comment
    expect(comment.comment).to eq(user2.name)
    expect(comment.eventable_id).to eq(user_like.id.to_s)
    expect(comment.eventable_type).to eq(user_like.class.name)
  end

  it 'should destroy comments with event_type = "like"' do
    timeline1 = create(:timeline, user: user)
    timeline1.activities.destroy_all

    user1 = create(:user)

    user_like = user1.like!(timeline1)
    expect(user_like.comment).to be
    comments = timeline1.reload.activities.to_a
    expect(comments.size).to eq(1)

    user_like = user1.unlike!(timeline1)
    comments = timeline1.reload.activities.to_a
    expect(comments.size).to eq(0)
  end

  it 'should not create duplicates on multiple calls for likes' do
    timeline1 = create(:timeline, user: user)
    timeline1.activities.destroy_all

    user1 = create(:user)

    3.times { user1.like!(timeline1) }
    comments = timeline1.reload.activities.to_a
    expect(comments.size).to eq(1)
  end
end
