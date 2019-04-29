UserAdataper = Struct.new(:current_user, :user) do
  delegate :email, :name, :username, :authentication_token, :first_name,
    :last_name, :background, :identifier, :profile_image, :user_type,
    :facebook_id, :followed_by?, :follows?, :id, :facebook_link, :ext_id,
    :is_verified, :contact_number, :login_method, to: :user

  def original
    user
  end

  def playlists
    playlists = [
      ::Playlists::Default.new(user),
      ::Playlists::Likes.new(user),
    ].map do |playlist|
      playlist.current_user = current_user
      playlist.params = {}
      playlist
    end

    scoped = if current_user != user
      user.playlists.where(is_private: false)
    else
      user.playlists
    end


    playlists.concat(scoped.to_a)
  end

  def user_followers
    scoped = User

    scoped = scoped.select(<<-SQL
      DISTINCT(users.*),
      EXISTS(
        SELECT 1 FROM user_followers
        WHERE
          user_followers.followed_id=users.id AND
          user_followers.follower_id=#{current_user.id} AND
          user_followers.is_followed=true
      ) AS is_followed
    SQL
    .squish)

    scoped = scoped.joins(<<-SQL
      INNER JOIN user_followers ON users.id = user_followers.follower_id
    SQL
    .squish)

    scoped = scoped.where("users.id != #{user.id} AND users.email != 'info@musicfeed.co' ")
    scoped = scoped.where("user_followers.followed_id = #{user.id}")

    User.find_by_sql(<<-SQL
      SELECT *
      FROM (#{scoped.to_sql}) AS fu
      ORDER BY
        fu.is_followed DESC,
        fu.timelines_count DESC,
        fu.username
    SQL
    .squish)
  end

  def user_followings
    scoped = User

    scoped = scoped.select(<<-SQL
      DISTINCT(users.*),
      EXISTS(
        SELECT 1 FROM user_followers
        WHERE
          user_followers.follower_id=#{user.id} AND
          user_followers.followed_id=users.id AND
          user_followers.is_followed=true
      ) AS is_followed
    SQL
    .squish)

    scoped = scoped.joins(<<-SQL
      LEFT JOIN user_followers ON users.id = user_followers.followed_id
      LEFT JOIN user_friends ON user_friends.friend1_id=users.id OR user_friends.friend2_id=users.id
    SQL
    .squish)

    scoped = scoped.where(<<-SQL
      users.id != #{user.id} AND
      users.email != 'info@musicfeed.co' AND
      (
        user_followers.follower_id = #{user.id} OR
        user_friends.friend1_id = #{user.id} OR user_friends.friend2_id = #{user.id}
      )
    SQL
    .squish)

    scoped = scoped.where("users.id != ?", user.id)

    User.find_by_sql(<<-SQL
      SELECT *
      FROM (#{scoped.to_sql}) AS fu
      WHERE fu.is_followed=true
      ORDER BY
        fu.is_followed DESC,
        fu.timelines_count DESC,
        fu.username
    SQL
    .squish)
  end

  def followers
    @followers ||= begin
                     collection = user_followers.map do |user|
                       UserAdataper.new(current_user, user)
                     end

                     friends_and_artists(collection)
                   end
  end

  def followings
    @followings ||= begin
                      collection = user_followings.map do |user|
                        UserAdataper.new(current_user, user)
                      end

                      friends_and_artists(collection)
                    end
  end

  def friends_and_artists(collection)
    artists = collection.select { |user| user.user_type == 'artist' }
    users = collection.select { |user| user.user_type == 'user' }
    { artists: artists, friends: users, }
  end

  def followings_count
    @followings_count ||= user.followed_count
  end

  def followers_count
    @followers_count ||= user.followers_count
  end

  def songs
    @songs ||= [] # songs_scope[1..-1] # -> timelines, activities, publishers
  end

  def playlists_count
    if user == current_user
      user.public_playlists.count + user.private_playlists.count
    else
      user.public_playlists.count
    end
  end

  def songs_count
    @songs_count ||= user.timelines_count
  end

  def is_followed?
    @is_followed ||= if user == current_user
                       true
                     elsif user.respond_to?(:is_followed)
                       user.is_followed
                     end
  end

  def secondary_emails
    @secondary_emails ||= user.secondary_emails
  end

  def secondary_phones
    @secondary_phones ||= user.secondary_phones
  end

  def artist?
    user.user_type == 'artist'
  end

  # @note In case of no facebook logged in users should have no expire
  # information.
  def is_facebook_expired?
    @is_facebook_expired ||= user.authentications.facebook.expired? rescue false
  end

  def suggestions_count
    # TODO: we should replace this number later by real suggestions count number.
    @suggestions_count ||= current_user.suggestions_count
  end

  def songs_scope
    @songs_scope ||= begin
                       timelines = Timeline
                                   .joins("LEFT JOIN timeline_publishers ON timeline_publishers.timeline_id=timelines.id")
                                   .joins("LEFT JOIN user_likes ON user_likes.timeline_id = timelines.id")
                                   .where("NOT(? = ANY(timelines.restricted_users)) AND (user_likes.user_id = ? OR timeline_publishers.user_identifier = ?)", user.id.to_s, user.id.to_s, user.facebook_id)
                                   .order("timelines.updated_at DESC")
                                   .limit(30)

                       timelines_count = timelines.except(:limit).count

                       timeline_ids = timelines.map(&:id).join(',')

                       timelines_collection = TimelinesCollection.new(user)
                       activities = timelines_collection.restricted_activities_for(timeline_ids)
                       publishers = timelines_collection.publishers_for(timeline_ids)

                       [timelines_count, timelines, activities, publishers]
                     end
  end

end
