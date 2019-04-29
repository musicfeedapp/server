require 'spec_helper'

describe Comment do
  let(:user) { create(:user) }

  it 'should track comments_count and activities_count' do
    timeline = create(:timeline, user: user, comments: [])
    timeline.activities.delete_all
    timeline.update_attributes!(activities_count: 0, comments_count: 0)

    timeline.reload

    comment1 = timeline.comments.create!(
      comment: 'test message',
      user_id: user.id,
    )

    expect(timeline.reload.comments_count).to eq(1)
    expect(timeline.reload.activities_count).to eq(1)

    comment2 = timeline.activities.create(
      comment: 'test message2',
      user_id: user.id,
      eventable_type: 'Timeline',
      eventable_id: timeline.id.to_s,
    )

    timeline.reload

    expect(timeline.reload.comments_count).to eq(1)
    expect(timeline.reload.activities_count).to eq(2)

    comment1.reload.destroy!
    expect(timeline.reload.comments_count).to eq(0)
    expect(timeline.reload.activities_count).to eq(1)

    comment2.reload.destroy!
    expect(timeline.reload.comments_count).to eq(0)
    expect(timeline.reload.activities_count).to eq(0)
  end
end

# == Schema Information
#
# Table name: comments
#
#  id               :integer          not null, primary key
#  comment          :text
#  commentable_id   :integer
#  commentable_type :string(255)
#  user_id          :integer
#  role             :string(255)      default("comments")
#  created_at       :datetime
#  updated_at       :datetime
#  eventable_type   :string           default("Comment")
#  eventable_id     :string
#
# Indexes
#
#  index_comments_on_commentable_id                       (commentable_id)
#  index_comments_on_commentable_id_and_commentable_type  (commentable_id,commentable_type)
#  index_comments_on_commentable_type                     (commentable_type)
#  index_comments_on_created_at_desc                      (created_at)
#  index_comments_on_eventable_type                       (eventable_type)
#  index_comments_on_user_id_asc                          (user_id)
#
