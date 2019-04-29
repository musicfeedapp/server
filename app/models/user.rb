class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable,
    :omniauthable,
    :omniauth_providers => [:facebook]

  mount_uploader :avatar, AvatarUploader

  attr_accessor :current_password

  # INFO: lets use facebook email later as the primary email address.
  # validates :email, presence: true

  def role?(r)
    self.role.to_s == r.to_s
  end

  include Socialable
  include Apiable
  # include Addressable
  include Nameable
  include Tokenable
  include ExternalTokenable
  include Followable
  include Friendable
  include Adminable
  include Likeable
  include Genreable

  include ElasticsearchSearchable
  include Searchable::UserExtension

  after_save do
    if self.name.present?
      IndexerWorker.perform_async(self.class.name,
                                  :index,
                                  id)
    end
  end

  after_destroy do
    if self.name.present?
      IndexerWorker.perform_async(self.class.name,
                                  :index,
                                  id)
    end
  end

  include CommonSql

  has_many :playlists

  scope :artist  , -> { where(user_type: 'artist') }
  scope :user    , -> { where(user_type: 'user') }
  scope :enabled , -> { where(enabled: true) }

  if Rails.env.development?
    def self.korsak
      where(email: 'alex.korsak@gmail.com').first
    end
  end

  class SuggestionFilter
    Filter = {
      artist:        ['Arts/Entertainment/Nightlife', 'Entertainer', 'Entertainment Website', 'Music', 'Musician/Band', 'Producer'],
      venue:         ['Bar', 'Club', 'Concert Tour', 'Concert Venue'],
      radio_station: ['Radio Station'],
      record_label:  ['Record Label'],
      trending:      ['Trending Artist']
    }

    def self.normalize(values)
      values.map do |value|
        if (collection = Filter[value.to_sym]).present?
          collection.map { |c| "'#{c.downcase}'" }.join(',')
        else
          "'#{value.downcase}'"
        end
      end.join(",")
    end
  end

  scope :with_is_followed, ->(user) {
    select(<<-SQL
      DISTINCT ON (users.id) users.*,
      EXISTS(
        SELECT 1 FROM user_followers
        WHERE
          user_followers.follower_id=#{user.id} AND
          user_followers.followed_id=users.id AND
          user_followers.is_followed=true
      ) AS is_followed,
      ARRAY(
        SELECT genres.name FROM user_genres
        INNER JOIN genres ON genres.id=user_genres.genre_id
        WHERE user_genres.user_id=users.id
      ) AS genres_names,
      CASE
        WHEN users.is_verified THEN 0
        ELSE 1
      END AS isv
    SQL
    .squish)
  }

  def private_playlists
    playlists.where(is_private: true)
  end

  def public_playlists
    playlists.where(is_private: false)
  end

  def identifier
    facebook_id.to_s
  end

  def user?
    user_type == 'user'
  end

  def artist?
    user_type == 'artist'
  end

  has_many :notifications, foreign_key: 'to_user_id', primary_key: 'id', class_name: 'UserNotification'

  def user_track_count(current_user)
    if self == current_user
      timelines_count + private_playlists_timelines_count
    else
      timelines_count
    end
  end

  # TODO: on login we should merge this user with the user that logged in to
  # the system.
  DEFAULT_USER_TYPE = 'user'
  def self.find_or_create_by_facebook_id_and_name(facebook_id, name)
    user = User.find_or_initialize_by(facebook_id: facebook_id.to_s)
    return user if user.persisted?

    user.enabled  = false
    user.email    = "#{facebook_id}@facebook.com"
    user.username = Usernameable.get(name)
    user.name     = name

    picture = "http://graph.facebook.com/#{facebook_id}/picture?type=large"
    user.facebook_profile_image_url = picture

    password = SecureRandom.base64
    user.password = password
    user.password_confirmation = password

    user.facebook_link = "https://www.facebook.com/#{facebook_id}"

    # @note by default we are using user type in case of trying to understand
    # is it artist or user we should use specific indentifier but for now it's
    # ok it will skip suggestions module for now.
    user.user_type = DEFAULT_USER_TYPE

    user.save!

    # We need to update on background username for the user as well.
    UsernamesWorker.perform_async(user.id)

    user
  end

  LIKE_TYPES = [
        'Arts/Entertainment/Nightlife',
        'Artist',
        'Bar',
        'Club',
        'Concert Tour',
        'Concert Venue',
        'Entertainer',
        'Music',
        'Musician/Band',
        'Producer',
        'Radio Station',
        'Record Label'
      ].map(&:downcase)

  def self.each_page(options = {})
    per = options[:per] || 25
    order_by = options[:order] || [:id, 1]

    i = 1
    until (current_page = self.order(order_by).page(i).per(per)).empty?
      yield current_page

      i = i + 1
    end
  end

  def self.trending_artist(current_user, options = {})
    artists = options.fetch(:artists) { [] }

    conditions = []
    conditions << "user_followers.follower_id != #{current_user.id}"
    conditions << "users.id NOT IN (#{current_user.restricted_suggestions.join(',')})" if current_user.restricted_suggestions.present?
    conditions << "user_followers.followed_id NOT IN (#{artists})" if artists.present?

    conditions = conditions.join(' AND ')

    User.find_by_sql(<<-SQL
      SELECT s2.id FROM (
        SELECT
          DISTINCT ON (s.id) s.id,
          s.user_follower_count,
          ARRAY(
            SELECT genres.name FROM user_genres
            INNER JOIN genres ON genres.id=user_genres.genre_id
            WHERE user_genres.user_id=s.id
          ) AS genres_names
        FROM (
          SELECT users.id, count(user_followers.id) as user_follower_count, is_verified AS is_verified_user
          FROM users
          INNER JOIN user_followers ON users.id = user_followers.followed_id
          WHERE
            users.user_type = 'artist'
            AND user_followers.created_at > current_date - interval '30' day
            AND #{conditions}
          GROUP BY users.id
        ) s
        ORDER BY s.id
      ) s2
      ORDER BY s2.user_follower_count DESC
      LIMIT 100
    SQL
    .squish).map(&:id)
  end

  PerPage = 100
  def trending_tracks(page_number=1)
    friends_of_friends_ids = self.friends_of_friends.pluck(:id).join(',')

    if self.followed_count > 10 && friends_of_friends_ids.present?
      timelines = Timeline.find_by_sql <<-SQL
        WITH ranked_comments AS (
            SELECT DISTINCT(comments.commentable_id),
            dense_rank() OVER (
                PARTITION BY comments.commentable_type, comments.commentable_id
                ORDER BY comments.created_at DESC
            ) AS rank
            FROM comments
            WHERE comments.user_id IN (#{friends_of_friends_ids}) AND comments.commentable_type='Timeline'
        ),

        ranked_user_likes AS (
            SELECT DISTINCT(user_likes.timeline_id),
            dense_rank() OVER (
                PARTITION BY user_likes.timeline_id
                ORDER BY user_likes.created_at DESC
            ) AS rank
            FROM user_likes
            WHERE user_likes.user_id IN (#{friends_of_friends_ids})
        ),

        timelines_ids AS (
            (SELECT DISTINCT(ranked_comments.commentable_id)
            FROM ranked_comments
            WHERE ranked_comments.rank < 2
            LIMIT 10)

            UNION ALL

            (SELECT DISTINCT(ranked_user_likes.timeline_id)
            FROM ranked_user_likes
            WHERE ranked_user_likes.rank < 2
            LIMIT 10)
        ),

        timelines AS (
            SELECT DISTINCT(timelines.*)
            FROM timelines
            WHERE timelines.id IN (SELECT * FROM timelines_ids)
        )

        SELECT * FROM timelines LIMIT #{PerPage} OFFSET #{(page_number - 1) * PerPage}
      SQL
      .squish
    else
      timelines = Timeline.find_by_sql <<-SQL
        WITH ranked_comments AS (
            SELECT DISTINCT(comments.commentable_id),
            dense_rank() OVER (
                PARTITION BY comments.commentable_type, comments.commentable_id
                ORDER BY comments.created_at DESC
            ) AS rank
            FROM comments
            WHERE comments.commentable_type='Timeline'
        ),

        ranked_user_likes AS (
            SELECT DISTINCT(user_likes.timeline_id),
            dense_rank() OVER (
                PARTITION BY user_likes.timeline_id
                ORDER BY user_likes.created_at DESC
            ) AS rank
            FROM user_likes
        ),

        timelines_ids AS (
            (SELECT DISTINCT(ranked_comments.commentable_id)
            FROM ranked_comments
            WHERE ranked_comments.rank < 2
            LIMIT 10)

            UNION ALL

            (SELECT DISTINCT(ranked_user_likes.timeline_id)
            FROM ranked_user_likes
            WHERE ranked_user_likes.rank < 2
            LIMIT 10)
        ),

        timelines AS (
            SELECT DISTINCT(timelines.*)
            FROM timelines
            WHERE timelines.id IN (SELECT * FROM timelines_ids)
        )

        SELECT * FROM timelines LIMIT #{PerPage} OFFSET #{(page_number - 1) * PerPage}
      SQL
      .squish
    end# followed_count > 10

    timeline_ids = timelines.map(&:id).join(',')

    timelines_collection = TimelinesCollection.new(self)
    activities = timelines_collection.restricted_activities_for(timeline_ids)
    publishers = timelines_collection.publishers_for(timeline_ids)

    return timelines, activities, publishers
  end # trending_artists

end

# == Schema Information
#
# Table name: users
#
#  id                                :integer          not null, primary key
#  email                             :string(255)      default(""), not null
#  encrypted_password                :string(255)      default(""), not null
#  reset_password_token              :string(255)
#  reset_password_sent_at            :datetime
#  remember_created_at               :datetime
#  sign_in_count                     :integer          default(0)
#  current_sign_in_at                :datetime
#  last_sign_in_at                   :datetime
#  current_sign_in_ip                :string(255)
#  last_sign_in_ip                   :string(255)
#  created_at                        :datetime
#  updated_at                        :datetime
#  role                              :string(255)
#  avatar                            :string(255)
#  first_name                        :string(255)
#  middle_name                       :string(255)
#  last_name                         :string(255)
#  facebook_link                     :string(255)
#  twitter_link                      :string(255)
#  google_plus_link                  :string(255)
#  linkedin_link                     :string(255)
#  facebook_avatar                   :string(255)
#  google_plus_avatar                :string(255)
#  linkedin_avatar                   :string(255)
#  authentication_token              :string(255)
#  facebook_profile_image_url        :string(255)
#  facebook_id                       :string(255)
#  background                        :string(255)
#  username                          :string
#  comments_count                    :integer          default(0)
#  enabled                           :boolean          default(TRUE)
#  website                           :text             default("0")
#  genres                            :text             default([]), is an Array
#  user_type                         :string(255)      default("user"), not null
#  followers_count                   :integer          default(0)
#  followed_count                    :integer          default(0)
#  friends_count                     :integer          default(0)
#  name                              :string(255)      not null
#  is_verified                       :boolean          default(FALSE)
#  ext_id                            :string
#  restricted_timelines              :integer          default([]), is an Array
#  restricted_users                  :string           default([]), is an Array
#  welcome_notified_at               :datetime
#  category                          :string
#  public_playlists_timelines_count  :integer          default(0)
#  private_playlists_timelines_count :integer          default(0)
#  aggregated_at                     :datetime
#  suggestions_count                 :integer          default(0)
#  contact_number                    :string
#  contact_list                      :hstore           default([]), is an Array
#  phone_artists                     :hstore           default([]), is an Array
#  device_id                         :string
#  last_feed_viewed_at               :datetime         default(Thu, 03 Dec 2015 09:09:51 UTC +00:00)
#  secondary_emails                  :text             default([]), is an Array
#  secondary_phones                  :text             default([]), is an Array
#  login_method                      :string
#  timelines_count                   :integer          default(0)
#  restricted_suggestions            :text             default([]), is an Array
#
# Indexes
#
#  index_users_on_authentication_token  (authentication_token) UNIQUE
#  index_users_on_category              (category)
#  index_users_on_created_at            (created_at)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_enabled               (enabled)
#  index_users_on_ext_id                (ext_id)
#  index_users_on_facebook_id           (facebook_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_user_type             (user_type)
#  index_users_on_username              (username)
#
