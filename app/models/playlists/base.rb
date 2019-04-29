module Playlists
  Base = Struct.new(:user) do
    attr_writer :params

    def params
      @params ||= {}
    end

    attr_accessor :current_user

    # @return timelines, activities, publishers
    def timelines
      @timelines ||= pagination(no_pagination_timelines)
    end

    def add_timeline(passed_timelines_ids)
      # should be implemented
    end

    def remove_timeline(passed_timelines_ids)
      # should be implemented
    end

    def pagination(timelines)
      timelines
    end

    def update_attributes(attributes = {})
      # nothing to do, our models are static.
    end
    alias_method :update_attributes!, :update_attributes

    def destroy
      # nothing to do, our models are static.
    end
    alias_method :destroy!, :destroy

    # json metadata goes below
    #
    def tracks_count
      # should be implemented
    end

    def picture_url
      @picture_url ||= timelines[0].try(:picture)
    end

    def is_private
      false
    end
  end
end
