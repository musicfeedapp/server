module Likeable

  def self.included(base)
    base.class_eval do
      has_many :likes, through: :user_likes, source: 'timeline'
      has_many :user_likes, foreign_key: 'user_id', primary_key: 'id', dependent: :destroy, class_name: 'UserLike'

      def like!(timeline, options = {})
        timeline_id = likeable_timeline_id(timeline)

        user_like = UserLike.find_or_create_by!(user_id: id, timeline_id: timeline_id)

        comment = Comment.find_or_initialize_by(
          commentable_id: timeline_id,
          commentable_type: Timeline.name,
          eventable_type: UserLike.name,
          user_id: id,
        )
        comment.eventable_id = user_like.id
        comment.comment = name
        comment.save!

        user_like
      end

      def unlike!(timeline, options = {})
        timeline_id = likeable_timeline_id(timeline)

        user_like = UserLike.find_by(user_id: id, timeline_id: timeline_id)
        user_like.destroy if user_like

        Comment.where(
          eventable_type: UserLike.name,
          user_id: id,
          commentable_id: timeline_id,
          commentable_type: Timeline.name,
        ).delete_all

        user_like
      end

      protected

      def likeable_timeline_id(timeline)
        if timeline.kind_of?(ActiveRecord::Base)
          timeline.id
        else
          timeline = PublisherTimeline.fetch(timeline)

          unless timeline.new_record?
            timeline.id
          else
            timeline = timeline.dup

            success, timeline = PublisherTimeline.find_or_create_for(self, timeline, disable_playlist_event: true)

            timeline.id if success
          end
        end
      end
    end
  end

end
