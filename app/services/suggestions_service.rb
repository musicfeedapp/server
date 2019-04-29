SuggestionsService = Struct.new(:current_user) do
  PerPage = 100

  # temporarily hidden the musicfeed user on Tyrone request
  # as we have assigned good number of the tracks which we
  # don't wanted to get deleted because of which Musicfeed user
  # was getting showed at top in suggestions

  def artists(page_number = 1)
    @artists ||= begin
                   conditions = []
                   conditions << "user_followers.follower_id in (#{following_user_ids})"                              if following_user_ids.present?
                   conditions << "user_followers.followed_id not in (#{following_artist_ids})"                        if following_artist_ids.present?
                   conditions << "suggestions.artists.email != 'info@musicfeed.co'"
                   conditions << "suggestions.artists.id not in (#{current_user.restricted_suggestions.join(',')})"   if current_user.restricted_suggestions.present?
                   conditions = conditions.join(' and ')

                   User.find_by_sql <<-SQL
                      SELECT
                        DISTINCT(suggestions.artists.*),
                        ARRAY(
                          SELECT genres.name FROM user_genres
                          INNER JOIN genres ON genres.id=user_genres.genre_id
                          WHERE user_genres.user_id=suggestions.artists.id
                        ) AS genres_names
                      FROM suggestions.artists
                      LEFT JOIN user_followers ON suggestions.artists.id = user_followers.followed_id
                      WHERE #{conditions}
                      ORDER BY
                        suggestions.artists.is_verified DESC,
                        suggestions.artists.timelines_count DESC,
                        suggestions.artists.followers_count DESC
                      LIMIT #{PerPage}
                      OFFSET #{(page_number - 1) * PerPage}
                   SQL
                   .squish
                 end
  end

  def artists_by_filter(filter, page_number=1)
    @artists ||= begin
                   filters = if filter.present?
                               User::SuggestionFilter.normalize(filter.split(','))
                             else
                               User::SuggestionFilter.normalize(User::LIKE_TYPES)
                             end

                   if filter.to_s.downcase == "trending"
                     trending_artists
                   else
                     conditions = []
                     conditions << "user_followers.follower_id in (#{following_user_ids})"                              if following_user_ids.present?
                     conditions << "user_followers.followed_id not in (#{following_artist_ids})"                        if following_artist_ids.present?
                     conditions << "suggestions.artists.email != 'info@musicfeed.co'"
                     conditions << "suggestions.artists.id not in (#{current_user.restricted_suggestions.join(',')})"   if current_user.restricted_suggestions.present?
                     conditions = conditions.join(' and ')

                     # TODO: replace it by Apache Hive, export timelines and
                     # comments as json.
                     user_ids = Rails.cache.fetch("#{current_user.facebook_id}:suggestions:#{filter}", expires_in: 23.hours) {
                       User.find_by_sql(<<-SQL
                          WITH custom_users AS (
                            (
                              SELECT u.id FROM (
                                SELECT
                                  DISTINCT(suggestions.artists.id),
                                  suggestions.artists.is_verified,
                                  suggestions.artists.timelines_count,
                                  suggestions.artists.followers_count
                                FROM suggestions.artists
                                LEFT JOIN user_followers ON suggestions.artists.id = user_followers.followed_id
                                WHERE #{conditions}
                                ORDER BY
                                  suggestions.artists.is_verified DESC,
                                  suggestions.artists.timelines_count DESC,
                                  suggestions.artists.followers_count DESC
                              ) u
                              LIMIT #{PerPage}
                            ) UNION ALL (
                              SELECT users.id
                              FROM users
                              WHERE users.id IN (
                                SELECT user_likes.user_id
                                FROM user_likes
                                WHERE user_likes.user_id NOT IN (SELECT followed_id FROM user_followers WHERE follower_id = #{current_user.id})
                              )
                              AND user_type = 'artist'
                              AND lower(users.category) IN (#{filters})
                              LIMIT #{PerPage}
                            ) UNION ALL (
                              SELECT users.id
                              FROM users
                              WHERE
                                users.facebook_id IN (
                                  SELECT user_identifier
                                  FROM timeline_publishers
                                  WHERE timeline_id IN (SELECT DISTINCT(unnest(timelines_ids)) FROM playlists WHERE user_id = #{current_user.id})
                                )
                                AND user_type = 'artist'
                                AND users.id NOT IN (SELECT followed_id FROM user_followers WHERE follower_id = #{current_user.id})
                                AND lower(users.category) IN (#{filters})
                              LIMIT #{PerPage}
                            )
                          )

                          (
                            SELECT DISTINCT ON (users.id) users.id
                            FROM users
                            WHERE EXISTS(SELECT 1 FROM custom_users WHERE custom_users.id=users.id)
                            ORDER BY users.id
                            LIMIT #{PerPage}
                            OFFSET #{(page_number - 1) * PerPage}
                          )
                          SQL
                          .squish
                       ).map(&:id)
                     }

                     if user_ids.present?
                       scoped = User
                         .select(%Q{
                          users.*,
                          ARRAY(
                            SELECT genres.name FROM user_genres
                            INNER JOIN genres ON genres.id=user_genres.genre_id
                            WHERE user_genres.user_id=users.id
                          ) AS genres_names,
                          users.is_verified AS is_verified_user
                         })

                         if following_artist_ids.present?
                           scoped = scoped.where("users.id not in (#{following_artist_ids})")
                         end

                         scoped
                           .where(id: user_ids)
                           .order('users.is_verified DESC')
                           .limit(100)
                           .offset((page_number - 1) * PerPage)
                     else
                       []
                     end
                   end
                 end
  end

  def get_facebook_ids(collection)
    collection
    .map(&:facebook_id)
    .uniq
    .map { |facebook_id| "'#{facebook_id}'" }
    .join(',')
  end

  def common_followers(artists = [])
    following_ids = (following_user_ids + "," + following_artist_ids).gsub(/^,|,$/,'')

    @common_followers ||= begin
                            hash = Hash.new { |h, k| h[k] = [] }

      if following_ids.present? && artists.present?
        scoped = User.find_by_sql(<<-SQL
          SELECT
            DISTINCT(users.*),
            user_followers.followed_id AS followed_artist_id,
            is_verified AS is_verified_user,
            followers_count AS user_follower_count
          FROM users
          INNER JOIN user_followers ON users.id = user_followers.follower_id
          WHERE
            user_followers.followed_id IN (#{artists.map(&:id).join(',')}) AND
            user_followers.follower_id IN (#{following_ids})
        SQL
        .squish)

        hash.merge(scoped.group_by(&:followed_artist_id))
      else
        hash
      end
    end
  end

  # @note timelines number per artists.
  TIMELINES_COUNT = 6

  def timelines
    @timelines ||= find_timelines(artists)
  end

  def trending_artists_timelines
    @timelines ||= find_timelines(trending_artists)
  end

  def find_timelines(a)
    artists_facebook_ids = get_facebook_ids(a)

    timelines = nil
    timeline_ids = nil

    timelines = Timeline.find_by_sql(<<-SQL
      WITH ranked_timelines AS (
        SELECT
          timelines.*,
          EXISTS(SELECT 1 FROM user_likes WHERE user_likes.timeline_id=timelines.id AND user_likes.user_id=#{current_user.id}) AS is_liked,
          dense_rank() OVER (
            PARTITION BY timeline_publishers.user_identifier
            ORDER BY timelines.created_at
          ) AS rank
        FROM timelines
        INNER JOIN timeline_publishers ON timeline_publishers.timeline_id=timelines.id
        WHERE timeline_publishers.user_identifier IN (#{artists_facebook_ids.blank? ? "'unknown'" : artists_facebook_ids})
      )

      SELECT ranked_timelines.* FROM ranked_timelines WHERE ranked_timelines.rank < #{TIMELINES_COUNT + 1};
    SQL
    .squish)

    timeline_ids = timelines.map(&:id).join(',')

    timelines_collection = TimelinesCollection.new(current_user)

    publishers = nil
    publishers = timelines_collection.publishers_for(timeline_ids)

    activities = nil
    activities = timelines_collection.restricted_activities_for(timeline_ids)

    timelines = publishers.values.flatten.group_by(&:user_id).inject(Hash.new { |h,k| h[k] = [] }) do |hash, (user_id, values)|
      ts = values.map(&:timeline_id)

      timelines -= timelines.map do |timeline|
        if ts.include?(timeline.id)
          hash[user_id] << timeline
          timeline
        end
      end

      hash
    end

    return timelines, activities, publishers
  end

  def artists_count
    artists.to_a.size
  end

  # artists which have been followed the most number of times in the last 30 days
  def trending_artists
    @trending_artists ||= begin
                            user_ids = Rails.cache.fetch("#{current_user.facebook_id}:suggestions:trending", expires_in: 24.hours) {
                              User.trending_artist(current_user, artists: following_artist_ids)
                            }

                            if user_ids.present?
                              scoped = User
                                       .select(%Q{
                                          users.*,
                                          ARRAY(
                                            SELECT genres.name FROM user_genres
                                            INNER JOIN genres ON genres.id=user_genres.genre_id
                                            WHERE user_genres.user_id=users.id
                                          ) AS genres_names,
                                          users.is_verified AS is_verified_user
                                        })

                              if following_artist_ids.present?
                                scoped = scoped.where("users.id not in (#{following_artist_ids})")
                              end

                              scoped
                                .where(id: user_ids)
                                .order('users.is_verified DESC')
                                .limit(100)
                            else
                              []
                            end
                          end
  end

  def trending_tracks
    @trending_tracks ||= current_user.trending_tracks
  end

  private

  def followings
    @followings ||= begin
                      values = current_user.followed.pluck(:id, :user_type).group_by { |v| v[1] }

                      {
                        artists: values["artist"].to_a.map { |v| v[0] }.join(','),
                        users: values["user"].to_a.map { |v| v[0] }.join(',')
                      }
                    end
  end

  def following_user_ids
    followings[:users]
  end

  def following_artist_ids
    followings[:artists]
  end
end
