module Playlists
  class Default < Base
    def no_pagination_timelines
      @no_pagination_timelines ||= begin
                                     timelines_collection = TimelinesCollection.new(user, params.merge(per_page: 100))
                                     timelines_collection.default(current_user)
                                   end
    end

    def add_timeline(passed_timelines_ids)
      # nothing to do
    end

    def remove_timeline(passed_timelines_ids)
      # nothing to do
    end

    # force to have empty list because of we should never use ids here.
    # we have specific query to run
    def timelines_ids
      []
    end

    # json metadata goes below
    #
    def id
      'default'
    end

    def tracks_count
      timelines_collection = TimelinesCollection.new(user, per_page: 100)
      timelines_collection.default_count(current_user)
    end

    def title
      if current_user.id == user.id
        "all my tracks"
      else
        "all tracks"
      end
    end

    def eventable_type
      'Playlist'
    end
  end
end
