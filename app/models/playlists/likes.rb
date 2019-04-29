module Playlists
  class Likes < Base
    def no_pagination_timelines
      @no_pagination_timelines ||= begin
                                     timelines_collection = TimelinesCollection.new(user, params.merge(per_page: 100))
                                     timelines_collection.liked(current_user)
                                   end
    end

    def add_timeline(passed_timelines_ids)
      passed_timelines_ids.each do |timeline_id|
        user.like!(timeline_id)
      end
    end

    def remove_timeline(passed_timelines_ids)
      passed_timelines_ids.each do |timeline_id|
        user.unlike!(timeline_id)
      end
    end

    # force to have empty list because of we should never use ids here.
    # we have specific query to run
    def timelines_ids
      []
    end

    # json metadata goes below

    def id
      'likes'
    end

    def tracks_count
      timelines_collection = TimelinesCollection.new(user, per_page: 100)
      timelines_collection.liked_count(current_user)
    end

    def title
      if current_user.id == user.id
        "My Loved Tracks"
      else
        "Loved Tracks"
      end
    end

    def eventable_type
      'Playlist'
    end
  end
end
