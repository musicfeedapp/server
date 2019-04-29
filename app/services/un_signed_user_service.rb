UnSignedUserService = Struct.new(:current_user, :params) do
  PAGINATION_NEXT_BLOCK = 100

  def timelines
    @timelines ||= begin
                     timelines = Timeline
                                 .joins(:timeline_publishers)
                                 .where("timeline_publishers.user_identifier IN (?)", artist_facebook_ids)
                                 .order("timelines.created_at DESC")

                     timeline_ids = timelines.map(&:id)

                     if timeline_ids.blank?
                       [[], [], []]
                     else
                       timelines_collection = TimelinesCollection.new(current_user, params)

                       timeline_ids = timeline_ids.join(',')

                       publishers = timelines_collection.publishers_for(timeline_ids)
                       activities = timelines_collection.restricted_activities_for(timeline_ids)
                       timelines = timelines_collection.pagination(timelines)

                       [timelines, activities, publishers]
                     end
                   end
  end

  def artists
    @artists ||= current_user.multiple_artist_search.records
  end

  def artist_facebook_ids
    @artist_facebook_ids ||= artists.pluck(:facebook_id).uniq
  end

  def create_unsigned_user!(phone_artists)
    if current_user.new_record?
      current_user.email = "#{current_user.device_id}@device_id.com"
      current_user.password = Devise.friendly_token[0, 20]
    end

    current_user.phone_artists = phone_artists

    current_user.save!
    current_user
  end
end
