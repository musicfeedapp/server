class Timeline < ActiveRecord::Base
  validates_presence_of :name, :link, :feed_type

  has_one :review

  # we should populate last_feed_appearance_timestamp before to show list in the api
  attr_accessor :generated_id, :is_posted, :last_feed_appearance_timestamp

  # temporary user for assigning and using on timeline_publishers creation in the tests
  attr_accessor :user

  TYPES = {
    spotify:      'spotify',
    youtube:      'youtube',
    soundcloud:   'soundcloud',
    shazam:       'shazam',
    grooveshark:  'grooveshark',
    mixcloud:     'mixcloud',
  }

  scope :suggestions, -> { limit(5) }

  scope :spotify,     -> { where(feed_type: TYPES[:spotify]) }
  scope :youtube,     -> { where(feed_type: TYPES[:youtube]) }
  scope :mixcloud,    -> { where(feed_type: TYPES[:mixcloud]) }
  scope :soundcloud,  -> { where(feed_type: TYPES[:soundcloud]) }
  scope :shazam,      -> { where(feed_type: TYPES[:shazam]) }
  scope :grooveshark, -> { where(feed_type: TYPES[:grooveshark]) }

  scope :skip_restricted, -> (user) {  }
  scope :only_restricted, -> (user) { where("? = ANY(timelines.restricted_users)", user.id) }

  has_many :likes, through: :user_likes, source: 'user'
  has_many :user_likes, foreign_key: 'timeline_id', primary_key: 'id', dependent: :destroy, class_name: 'UserLike'

  attr_accessor :custom_id

  alias_attribute :source, :link

  acts_as_commentable

  has_many :comments, -> { where(eventable_type: 'Comment') }, :as => :commentable
  has_many :activities, -> { where(commentable_type: 'Timeline') }, class_name: 'Comment', foreign_key: 'commentable_id'

  # `message` is coming from facebook message
  # `disable_playlist_event` - we should disable to create playlist comment in
  # case of having empty message and having separate comment creation in case
  # of adding to the playlist the new timeline.
  attr_accessor :message, :disable_playlist_event

  def self.per_page
    50
  end

  def self.api
    select("timelines.*")
  end

  SUGGESTIONS_PER_PAGE = 30
  def self.suggestions_for(user, facebook_id)
    timelines = self
      .where("timeline_publishers.user_identifier = ? AND users.user_type = 'artist'", facebook_id.to_s)
      .joins("INNER JOIN timeline_publishers ON timeline_publishers.timeline_id = timelines.id")
      .joins("INNER JOIN users ON users.facebook_id = timeline_publishers.user_identifier")
      .select(<<-SQL
          timelines.*,
        SQL
        .squish)
      .limit(SUGGESTIONS_PER_PAGE)

    timelines = timelines.to_a
    timeline_ids = timelines.map(&:id).join(',')

    timelines_collections = TimelinesCollection.new(user)
    publishers = timelines_collections.publishers_for(timeline_ids)
    activities = timelines_collections.restricted_activities_for(timeline_ids)

    return timelines, activities, publishers
  end

  has_many :timeline_publishers
  has_many :publishers, through: :timeline_publishers, source: :user

  include ElasticsearchSearchable
  include Searchable::TimelineExtension

  # TODO: enable it again after the migration finishs to work
  # after that we should run Timeline.import to reindex the data.
  #
  after_save  { IndexerWorker.perform_async(self.class.name, :index,  id) }
  after_destroy { IndexerWorker.perform_async(self.class.name, :delete, id) }

  include CommonSql

  paginates_per self.per_page

  def accessible_link
    return "https://www.youtube.com/watch?v=#{youtube_id}" if feed_type == 'youtube'
    return "https://www.youtube.com/watch?v=#{youtube_id}" if feed_type == 'shazam'
    link
  end
end

require_relative 'timeline/queries'

# == Schema Information
#
# Table name: timelines
#
#  id                        :integer          not null, primary key
#  name                      :string(255)
#  description               :text
#  link                      :text
#  picture                   :text
#  created_at                :datetime
#  updated_at                :datetime
#  feed_type                 :string(255)      not null
#  identifier                :string(255)
#  likes_count               :integer          default(0)
#  published_at              :datetime
#  youtube_id                :string(255)
#  enabled                   :boolean          default(TRUE)
#  artist                    :string(255)
#  album                     :string(255)
#  source                    :string(255)
#  source_link               :text
#  youtube_link              :string(255)
#  restricted_users          :integer          default([]), is an Array
#  likes                     :integer          default([]), is an Array
#  font_color                :string
#  genres                    :string           default([]), is an Array
#  comments_count            :integer          default(0)
#  itunes_link               :string
#  stream                    :text
#  default_playlist_user_ids :integer          default([]), is an Array
#  activities_count          :integer          default(0)
#  import_source             :string           default("feed")
#  category                  :string
#  view_count                :integer          default(0)
#  change_view_count         :integer          default(0)
#
# Indexes
#
#  index_timeline_publishers_on_created_at_desc                    (created_at)
#  index_timelines_on_created_at                                   (created_at)
#  index_timelines_on_feed_type                                    (feed_type)
#  index_timelines_on_id_asc                                       (id)
#  index_timelines_on_identifier                                   (identifier)
#  index_timelines_on_published_at_desc                            (published_at)
#  index_timelines_on_source_link                                  (source_link)
#  index_timelines_on_youtube_link                                 (youtube_link)
#  index_timelines_on_youtube_link_and_source_link_and_identifier  (youtube_link,source_link,identifier)
#  timelines_identifier_unique_contraint                           (identifier) UNIQUE
#  timelines_likes_rdtree_idx                                      (likes)
#
