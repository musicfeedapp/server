class Comment < ActiveRecord::Base
  include ActsAsCommentable::Comment

  belongs_to :commentable, :polymorphic => true

  # lets say:
  # - someone added this song to playlist
  # - someone liked this track
  belongs_to :eventable, :polymorphic => true

  default_scope -> { order('created_at ASC') }

  # NOTE: install the acts_as_votable plugin if you
  # want user to vote on the quality of comments.
  #acts_as_voteable

  belongs_to :user, counter_cache: :comments_count

  after_create do
    commentable.sql_increment!(
      [
        {
          name: :comments_count,
          by: comment? ? 1 : 0,
        },
        {
          name: :activities_count,
          by: 1,
        }
      ]
    )
  end

  after_destroy do
    commentable.sql_increment!(
      [
        {
          name: :comments_count,
          by: comment? ? -1 : 0,
        },
        {
          name: :activities_count,
          by: -1,
        }
      ]
    )
  end

  def comment?
    eventable_type.nil? || eventable_type == 'Comment'
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
