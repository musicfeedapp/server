class Playlist < ActiveRecord::Base
  validates_presence_of :title

  belongs_to :user, touch: true

  include ElasticsearchSearchable
  include Searchable::PlaylistExtension

  after_save { IndexerWorker.perform_async(self.class.name, :index,  id) }
  after_destroy { IndexerWorker.perform_async(self.class.name, :delete, id) }

  def tracks_count
    timelines_ids.size
  end

  attr_accessor :current_user, :params

  # TODO: extract to service and add support for pagination like we have for
  # Playlists::Default and Playlists::Likes predefined playlists.
  #
  # @return timelines, publishers collection for accessing timelines, users.username, users.facebook_id
  def timelines
    return [], [], [] if timelines_ids.blank?

    timelines_ids_join = timelines_ids.join(',')

    u = current_user.blank? ? user : current_user

    timelines = Timeline.find_by_sql(<<-SQL
      SELECT timelines.*,

        EXISTS(
            SELECT 1
            FROM user_likes
            WHERE user_likes.user_id=#{u.id} AND user_likes.timeline_id=timelines.id
        ) AS is_liked

        FROM (
          SELECT DISTINCT ON(timelines.id) timelines.*
          FROM timelines
          WHERE timelines.id IN (#{timelines_ids_join})
        ) AS timelines

      ORDER BY idx(array[#{timelines_ids_join}], timelines.id) DESC
    SQL
    .squish)

    timelines_collection = TimelinesCollection.new(u)
    publishers = timelines_collection.publishers_for(timelines_ids_join)
    activities = timelines_collection.restricted_activities_for(timelines_ids_join)

    return timelines, activities, publishers
  end

  def add_timeline(passed_timelines_ids)
    Playlist.transaction do
      # we should ensure that we are creating timelines from temp cached versions as well.
      passed_timelines_ids = Array(passed_timelines_ids).map do |timeline_id|
        # in some cases we could have temp timeline attributes
        # because of recognition using gracenote api.
        timeline = PublisherTimeline.fetch(timeline_id)

        unless timeline.new_record?
          timeline.id
        else
          timeline = timeline.dup

          success, timeline = PublisherTimeline.find_or_create_for(user, timeline, disable_playlist_event: true)

          timeline.id if success
        end
      end

      self.timelines_ids = (self.timelines_ids + Array(passed_timelines_ids)).uniq
      timelines_ids_will_change!

      timeline_ids_size = passed_timelines_ids.to_a.size
      user.sql_increment!([{name: "#{playlist_type}_playlists_timelines_count", by: timeline_ids_size}])

      t, _p = timelines

      # We should have up to date picture url for cover in the app
      self.picture_url = t.first.try(:picture)

      save!
    end

    self
  end

  def remove_timeline(passed_timelines_ids)
    Playlist.transaction do
      Array(passed_timelines_ids).each do |timeline_id|
        timelines_ids.delete(timeline_id)
      end

      timeline_ids_size = passed_timelines_ids.to_a.size
      user.sql_increment!([{name: "#{playlist_type}_playlists_timelines_count", by: -timeline_ids_size}])

      timelines_ids_will_change!

      t, _p = timelines

      # We should have up to date picture url for cover in the app
      self.picture_url = t.first.try(:picture)

      Playlist.record_timestamps = false
      begin
        save!
      ensure
        Playlist.record_timestamps = true
      end
    end

    self
  end

  def tracks_count
    timelines_ids.size
  end

  def playlists_timelines_count
    timelines_count = timelines_ids.size

    if previous_changes[:is_private] == [true, false]
      [{ name: "private_playlists_timelines_count", by:  -timelines_count }, { name: "public_playlists_timelines_count",  by: timelines_count }]
    else
      [{ name: "private_playlists_timelines_count", by: timelines_count }, { name: "public_playlists_timelines_count",  by: -timelines_count }]
    end
  end

  def playlist_type
    is_private ? "private" : "public"
  end

  def eventable_type
    'Playlist'
  end
end

# == Schema Information
#
# Table name: playlists
#
#  id            :integer          not null, primary key
#  title         :string(255)
#  user_id       :integer
#  created_at    :datetime
#  updated_at    :datetime
#  timelines_ids :integer          default([]), is an Array
#  picture_url   :text
#  is_private    :boolean          default(FALSE), not null
#  import_source :string
#
# Indexes
#
#  index_playlists_on_is_private       (is_private)
#  index_playlists_on_user_id          (user_id)
#  playlists_timelines_ids_rdtree_idx  (timelines_ids)
#
