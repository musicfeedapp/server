# In case of having temp timeline id as param we should take
# attributes from Rails.cache and instantiate Timeline object.
module PublisherTimeline
  def self.fetch(id)
    attributes = Cache.get(id.to_s)

    if attributes
      Marshal.load(attributes)
    else
      Timeline.find(id)
    end
  end

  def self.find_or_create_for(user, timeline, options = {})
    users = Array(user)

    conditions = []
    conditions.push("timelines.youtube_link = '#{timeline.youtube_link}'") if timeline.youtube_link.present?
    conditions.push("timelines.source_link = '#{timeline.source_link}'") if timeline.source_link.present?
    conditions.push("timelines.identifier = '#{timeline.identifier}'") if timeline.identifier.present?

    existing_timeline = Timeline.where(conditions.join(' OR ')).first

    if existing_timeline.blank?
      timeline.id = timeline.id || nil
      timeline.published_at = timeline.published_at || DateTime.now
      timeline.disable_playlist_event = timeline.disable_playlist_event || options.fetch(:disable_playlist_event) { true }

      # TODO: we should notify to our client developers that we are going to
      # have one more event for `published` timelines as result we will have
      # multiple posters thers.
      response = timeline.save.tap do |success|
        if success
          users.each do |user|
            eventable_id = options.fetch(:eventable_id) { 'published' }

            timeline.comments.create(
              commentable: timeline,
              eventable_type: 'Timeline',
              eventable_id: eventable_id,
              user: user,
              created_at: eventable_id == 'published' ? timeline.published_at : DateTime.now,
            )
          end
        end
      end
    else
      existing_timeline.view_count ||= 0

      if existing_timeline.view_count != 0
        existing_timeline.change_view_count = timeline.view_count - existing_timeline.view_count
        existing_timeline.view_count = timeline.view_count
      end

      existing_timeline.disable_playlist_event = timeline.disable_playlist_event || options.fetch(:disable_playlist_event) { true }

      response = existing_timeline.save.tap do |success|
        eventable_id = options.fetch(:eventable_id) { 'published' }

        if success
          users.each do |user|
            existing_timeline.comments.create(
              commentable: existing_timeline,
              eventable_type: 'Timeline',
              eventable_id: eventable_id,
              user: user,
              created_at: eventable_id == 'published' ? timeline.published_at : DateTime.now,
            )
          end
        end
      end
    end

    users.each do |user|
      if response
        timeline = existing_timeline || timeline

        # we should track publishers on creating the new timeline.
        timeline.timeline_publishers.find_or_create_by(
          user_identifier: user.facebook_id,
          timeline_id: timeline.id,
        )

        unless timeline.disable_playlist_event
          # we should create event on add to the default playlist.
          timeline.comments.create!(
            commentable: timeline,
            eventable_type: 'Playlist',
            eventable_id: 'default',
            created_at: DateTime.now,
            user: user,
          )
        end
      end
    end

    if response
      if timeline.message.present?
        timeline.comments.create!(
          comment: timeline.message,
          eventable_type: 'Comment',
          commentable: timeline,
          created_at: DateTime.now,
          user: users.first,
        )
      end
    end

    [response, timeline]
  end
end
