require 'benchmark'

TimelinesCollection = Struct.new(:user, :params) do
  def initialize(user, params = {})
    super(user, params)
  end

  def self.find_by(user, params = {})
    timelines_collection = TimelinesCollection.new(user, params)
    timelines_collection.find
  end

  # @notes:
  # - if your friend liked the post we should see that the friend liked the
  # post
  # - we should have activities for the posts(liked)

  def followings
    @followings ||= user.followed.select('users.id, users.facebook_id').to_a
  end

  def followings_facebook_ids
    @followings_facebook_ids ||= followings.map {|a| "'#{a.facebook_id}'"}.join(',')
  end

  def followings_user_ids
    @followings_user_ids ||= followings.map {|a| "#{a.id}"}.join(',')
  end

  def find_by_shared(options = {})
    users_conditions = []
    users_conditions.push("tp.user_identifier IN (#{followings_facebook_ids})") if followings.present?
    users_conditions = users_conditions.join(' OR ')

    sql = %Q{
        (
          WITH top_timeline_publishers AS (
            SELECT t.* FROM (
              SELECT *, DENSE_RANK() OVER (ORDER BY created_at DESC) tp_rank
              FROM timeline_publishers tp
              WHERE
                tp.user_identifier = '#{user.facebook_id}'
                #{ users_conditions.present? ? "OR #{users_conditions}" : "" }
            ) t
            WHERE t.tp_rank <= 1000
          )
          SELECT
            DISTINCT t3.*
          FROM (
            SELECT
              t2.*,
              CASE
                WHEN t2.last_feed_appearance_timestamp >= current_date - interval '1' day THEN t2.counter
                ELSE 0
              END AS shares_count
            FROM (
              SELECT
                t.*,
                dense_rank() OVER (
                  PARTITION BY t.id
                  ORDER BY t.last_feed_appearance_timestamp DESC
                ) AS rank
              FROM (
                SELECT
                  timelines.*,
                  tp.created_at AS last_feed_appearance_timestamp,
                  EXISTS(SELECT 1 FROM user_likes ul WHERE ul.timeline_id=timelines.id AND ul.user_id=#{user.id}) AS is_liked,
                  (
                    SELECT
                      (SELECT COUNT(t4.id) FROM timeline_publishers t4 WHERE t4.timeline_id=timelines.id AND t4.updated_at > current_date - interval '30' day) +
                      (SELECT COUNT(t4.id) FROM user_likes t4 WHERE t4.timeline_id=timelines.id AND t4.updated_at > current_date - interval '30' day)
                  ) AS counter
                FROM timelines
                INNER JOIN top_timeline_publishers tp ON tp.timeline_id=timelines.id
                WHERE
                    #{ conditions.present? ? "(#{conditions})" : "" }
              ) t
            ) t2
            WHERE t2.rank < 2
          ) t3
          ORDER BY
            t3.shares_count DESC NULLS LAST,
            t3.last_feed_appearance_timestamp DESC
        )
    }
    .squish

    Benchmark.bm do |benchmark|
      timelines = nil

      benchmark.report do
        sql = Timeline.connection.unprepared_statement { "(#{sql}) AS timelines" }
        timelines = Timeline.from(sql)
        timelines = pagination(timelines)
      end

      benchmark.report do
        timelines = timelines.to_a
      end

      timeline_ids = nil

      benchmark.report do
        timeline_ids = timelines.map(&:id).join(',')
      end

      return [], [], [] if timeline_ids.blank?

      return timelines, nil, nil if options.fetch(:only_timelines) { false }

      activities = nil
      benchmark.report do
        activities = activities_for(timeline_ids)
      end

      publishers = nil
      benchmark.report do
        publishers = publishers_feed_for(timeline_ids)
      end

      return timelines, activities, publishers
    end
  end

  def find(options = {})
    users_conditions = []
    users_conditions.push("tp.user_identifier IN (#{followings_facebook_ids})") if followings.present?
    users_conditions = users_conditions.join(' OR ')

    sql = %Q{
        (
          WITH top_timeline_publishers AS (
            SELECT t.* FROM (
              SELECT *, DENSE_RANK() OVER (ORDER BY created_at DESC) tp_rank
              FROM timeline_publishers tp
              WHERE
                tp.user_identifier = '#{user.facebook_id}'
                #{ users_conditions.present? ? "OR #{users_conditions}" : "" }
            ) t
            WHERE t.tp_rank <= 1000
          )
          SELECT
          DISTINCT t2.*
          FROM (
            SELECT
              t.*,
              dense_rank() OVER (
                PARTITION BY t.id
                ORDER BY t.last_feed_appearance_timestamp DESC
              ) AS rank
            FROM (
              SELECT
                timelines.*,
                tp.created_at AS last_feed_appearance_timestamp,
                EXISTS(SELECT 1 FROM user_likes ul WHERE ul.timeline_id=timelines.id AND ul.user_id=#{user.id}) AS is_liked
              FROM timelines
              INNER JOIN top_timeline_publishers tp ON tp.timeline_id=timelines.id
              WHERE
                  #{ conditions.present? ? "(#{conditions})" : "" }
            ) t
            ) t2
          WHERE t2.rank < 2
          ORDER BY t2.last_feed_appearance_timestamp DESC
        )
    }
    .squish

    Benchmark.bm do |benchmark|
      timelines = nil

      benchmark.report do
        sql = Timeline.connection.unprepared_statement { "(#{sql}) AS timelines" }
        timelines = Timeline.from(sql)
        timelines = pagination(timelines)
      end

      benchmark.report do
        timelines = timelines.to_a
      end

      timeline_ids = nil

      benchmark.report do
        timeline_ids = timelines.map(&:id).join(',')
      end

      return [], [], [] if timeline_ids.blank?

      return timelines, nil, nil if options.fetch(:only_timelines) { false }

      activities = nil
      benchmark.report do
        activities = activities_for(timeline_ids)
      end

      publishers = nil
      benchmark.report do
        publishers = publishers_feed_for(timeline_ids)
      end

      return timelines, activities, publishers
    end
  end

  def liked(current_user)
    sql = %Q{
        (
          SELECT t.* FROM (
            SELECT DISTINCT ON (timelines.id) timelines.*, user_likes.created_at AS last_feed_appearance_timestamp
            FROM timelines
            INNER JOIN user_likes ON user_likes.timeline_id=timelines.id
            INNER JOIN users ON users.id=user_likes.user_id
            INNER JOIN timeline_publishers ON timeline_publishers.timeline_id=timelines.id
            WHERE
              user_likes.user_id=#{user.id}
              #{ conditions.present? ? " AND " + conditions : "" }
            ORDER BY timelines.id
        ) t
        ORDER BY t.last_feed_appearance_timestamp DESC
      )
    }
    .squish

    sql = Timeline.connection.unprepared_statement { "(#{sql}) AS timelines" }
    timelines = Timeline.from(sql)
    timelines = pagination(timelines)
    timelines = timelines.to_a

    timeline_ids = timelines.map(&:id).join(',')
    return [], [], [] if timeline_ids.blank?

    activities = restricted_activities_for(timeline_ids)
    publishers = publishers_for(timeline_ids)

    return timelines, activities, publishers
  end

  def liked_count(current_user)
    sql = %Q{
        (
          SELECT t.* FROM (
            SELECT DISTINCT ON (timelines.id) timelines.*, user_likes.created_at AS last_feed_appearance_timestamp
            FROM timelines
            INNER JOIN user_likes ON user_likes.timeline_id=timelines.id
            INNER JOIN users ON users.id=user_likes.user_id
            INNER JOIN timeline_publishers ON timeline_publishers.timeline_id=timelines.id
            WHERE
              user_likes.user_id=#{user.id}
              #{ conditions.present? ? " AND " + conditions : "" }
            ORDER BY timelines.id
          ) t
          ORDER BY t.last_feed_appearance_timestamp DESC
        )
    }.squish

    sql = Timeline.connection.unprepared_statement { "(#{sql}) AS timelines" }
    Timeline.from(sql).except(:select).count
  end

  def default(current_user)
    sql = %Q{
        (
          SELECT t.* FROM (
            SELECT
              DISTINCT ON (timelines.id) timelines.*,
              timelines.published_at AS last_feed_appearance_timestamp,
              EXISTS(SELECT 1 FROM user_likes ul WHERE ul.timeline_id=timelines.id AND ul.user_id=#{user.id}) AS is_liked
            FROM timelines
            INNER JOIN timeline_publishers tp ON tp.timeline_id=timelines.id
            WHERE
                tp.user_identifier='#{user.facebook_id}'
                #{ conditions.present? ? "AND (#{conditions})" : "" }
            ORDER BY timelines.id
          ) t
          ORDER BY t.last_feed_appearance_timestamp DESC
        )
    }
    .squish

    sql = Timeline.connection.unprepared_statement { "(#{sql}) AS timelines" }
    timelines = Timeline.from(sql)
    timelines = pagination(timelines)
    timelines = timelines.to_a

    timeline_ids = timelines.map(&:id).join(',')
    return [], [], [] if timeline_ids.blank?

    activities = activities_for(timeline_ids)
    publishers = publishers_feed_for(timeline_ids)

    return timelines, activities, publishers
  end

  def default_count(current_user)
    sql = %Q{
        (
          SELECT t.* FROM (
            SELECT
              DISTINCT ON (timelines.id) timelines.*,
              tp.created_at AS last_feed_appearance_timestamp,
              EXISTS(SELECT 1 FROM user_likes ul WHERE ul.timeline_id=timelines.id AND ul.user_id=#{user.id}) AS is_liked
            FROM timelines
            INNER JOIN timeline_publishers tp ON tp.timeline_id=timelines.id
            WHERE
                tp.user_identifier='#{user.facebook_id}'
                #{ conditions.present? ? "AND (#{conditions})" : "" }
            ORDER BY timelines.id
          ) t
        )
    }
    .squish

    sql = Timeline.connection.unprepared_statement { "(#{sql}) AS timelines" }
    Timeline.from(sql).except(:select).count
  end

  def activities_for(timeline_ids)
    return {} if timeline_ids.blank?

    sql = <<-SQL
        WITH followings AS (
          SELECT user_followers.followed_id AS id
          FROM user_followers
          WHERE user_followers.follower_id = #{user.id} AND user_followers.is_followed=true
        ),

        followings_comments AS (
          SELECT comments.*,
          dense_rank() OVER (
            PARTITION BY comments.commentable_type, comments.commentable_id
            ORDER BY comments.created_at DESC
          ) AS rank
          FROM comments
          WHERE
            comments.commentable_type='Timeline' AND
            comments.commentable_id IN (#{timeline_ids}) AND
            (comments.user_id=#{user.id} OR EXISTS(SELECT 1 FROM followings f WHERE comments.user_id=f.id))
        )

        (
          SELECT fc.commentable_id AS timeline_id, fc.eventable_type AS last_activity_eventable_type, fc.created_at AS last_activity_created_at, fc.user_id AS last_activity_user_id
          FROM followings_comments fc
          WHERE fc.rank < 2
          ORDER BY last_activity_created_at DESC
        )
    SQL

    Comment.find_by_sql(sql.squish).group_by { |c| c.timeline_id }
  end

  def publishers_for(timeline_ids, options = {})
    return {} if timeline_ids.blank?

    sql = <<-SQL
        WITH rank_publishers AS (
          SELECT tp.*,
          dense_rank() OVER (
            PARTITION BY tp.timeline_id
            ORDER BY tp.created_at DESC
          ) AS rank
          FROM timeline_publishers tp
          WHERE
            tp.timeline_id IN (#{timeline_ids})
        )

        (
          SELECT
            t.timeline_id AS timeline_id,
            us.name AS author,
            us.name AS author_name,
            'http://graph.facebook.com/' || us.facebook_id || '/picture?type=large' AS author_picture,
            us.facebook_id AS author_identifier,
            EXISTS(SELECT 1 FROM user_followers WHERE user_followers.follower_id=#{user.id} AND user_followers.followed_id=us.id AND user_followers.is_followed=true) AS author_is_followed,
            us.facebook_id AS user_identifier,
            us.ext_id AS author_ext_id,
            us.username AS username,
            us.is_verified AS is_verified_user,
            t.created_at,
            us.id AS user_id
          FROM (
            SELECT rp.*
            FROM rank_publishers rp
            WHERE rp.rank=1
          ) t
          INNER JOIN users us ON us.facebook_id=t.user_identifier
        )
    SQL

    TimelinePublisher.find_by_sql(sql.squish).group_by { |c| c[options.fetch(:key) { 'timeline_id' }] }
  end

  def publishers_feed_for(timeline_ids, options = {})
    return {} if timeline_ids.blank?

    sql = <<-SQL
        WITH rank_publishers AS (
          SELECT tp.*,
          dense_rank() OVER (
            PARTITION BY tp.timeline_id
            ORDER BY tp.created_at DESC
          ) AS rank
          FROM timeline_publishers tp
          WHERE
            tp.timeline_id IN (#{timeline_ids})
        )

        (
          SELECT
            t.timeline_id AS timeline_id,
            us.name AS author,
            us.name AS author_name,
            'http://graph.facebook.com/' || us.facebook_id || '/picture?type=large' AS author_picture,
            us.facebook_id AS author_identifier,
            EXISTS(SELECT 1 FROM user_followers WHERE user_followers.follower_id=#{user.id} AND user_followers.followed_id=us.id AND user_followers.is_followed=true) AS author_is_followed,
            us.facebook_id AS user_identifier,
            us.ext_id AS author_ext_id,
            us.username AS username,
            us.is_verified AS is_verified_user,
            t.created_at,
            us.id AS user_id
          FROM (
            SELECT rp.*
            FROM rank_publishers rp
            WHERE rp.rank=1
          ) t
          INNER JOIN users us ON us.facebook_id=t.user_identifier
        )
    SQL

    TimelinePublisher.find_by_sql(sql.squish).group_by { |c| c[options.fetch(:key) { 'timeline_id' }] }
  end

  def restricted_activities_for(timeline_ids, options = {})
    return {} if timeline_ids.blank?

    sql = <<-SQL
        WITH followings_comments AS (
          SELECT comments.*,
          dense_rank() OVER (
            PARTITION BY comments.commentable_type, comments.commentable_id
            ORDER BY comments.created_at DESC
          ) AS rank
          FROM comments
          WHERE
            comments.commentable_type='Timeline' AND
            comments.commentable_id IN (#{timeline_ids})
        )

        (
          SELECT fc.commentable_id AS timeline_id, fc.eventable_type AS last_activity_eventable_type, fc.created_at AS last_activity_created_at, fc.user_id AS last_activity_user_id, fc.user_id AS user_id
          FROM followings_comments fc
          WHERE fc.rank < 2
          ORDER BY last_activity_created_at DESC
        )
    SQL

    Comment.find_by_sql(sql.squish).group_by { |c| c[options.fetch(:key) { 'timeline_id' }] }
  end

  def restricted_feed_activities_for(timeline_ids, options = {})
    return {} if timeline_ids.blank?

    users_conditions = []
    users_conditions.push("comments.user_id IN (#{followings_user_ids})") if followings.present?
    users_conditions = users_conditions.join(' OR ')

    sql = <<-SQL
        WITH followings_comments AS (
          SELECT comments.*,
          dense_rank() OVER (
            PARTITION BY comments.commentable_type, comments.commentable_id
            ORDER BY comments.created_at DESC
          ) AS rank
          FROM comments
          WHERE
            comments.commentable_type='Timeline' AND
            comments.commentable_id IN (#{timeline_ids})
            #{ users_conditions.present? ? "AND #{users_conditions}" : "" }
        )

        (
          SELECT fc.commentable_id AS timeline_id, fc.eventable_type AS last_activity_eventable_type, fc.created_at AS last_activity_created_at, fc.user_id AS last_activity_user_id, fc.user_id AS user_id
          FROM followings_comments fc
          WHERE fc.rank < 2
          ORDER BY last_activity_created_at DESC
        )
    SQL

    Comment.find_by_sql(sql.squish).group_by { |c| c[options.fetch(:key) { 'timeline_id' }] }
  end

  def pagination(timelines)
    return timelines.limit(per_page) unless params[:last_timeline_id].present?

    puts 'start pagination'

    Benchmark.bm do |benchmark|
      scoped = nil

      benchmark.report do
        scoped = timelines.except(:select).select("timelines.id")
      end

      position = nil

      benchmark.report do
        position = Timeline.find_by_sql(<<-SQL
                                    SELECT t1.row FROM (
                                      SELECT CASE WHEN t2.id=#{params[:last_timeline_id]} THEN ROW_NUMBER() over() ELSE 0 END AS row
                                      FROM (#{scoped.to_sql}) t2
                                    ) t1
                                    WHERE t1.row > 0
                                    LIMIT 1
                                        SQL
                                        .squish)
        position = position.first.row
      end

      timelines = timelines.limit(per_page)
      return timelines unless position.present?

      timelines = timelines.where("timelines.id != ?", params[:last_timeline_id])
      return timelines.offset(position)
    end
  end

  PAGINATION_NEXT_BLOCK = 30
  def per_page
    params.fetch(:per_page) { PAGINATION_NEXT_BLOCK }
  end

private

  def conditions
    @conditions ||=
      [
        filter_by_types_conditions,
        filter_by_timestamp_conditions,
        filter_by_exclude_types_conditions,
        filter_by_restricted_conditions,
        filter_by_user_id_conditions,
        filter_by_import_source_conditions,
        filter_by_current_user_id_conditions,
      ].select(&:present?).join(' AND ')
  end

  def filter_by_restricted_conditions
    "NOT(#{user.id} = ANY(timelines.restricted_users))"
  end

  def filter_by_import_source_conditions
    timelines = Arel::Table.new(:timelines)
    timelines[:import_source].eq('feed').to_sql
  end

  def filter_by_types_conditions
    collection = params.fetch(:feed_type, [])

    return "" unless collection.present?

    timelines = Arel::Table.new(:timelines)
    timelines[:feed_type].in(collection).to_sql
  end

  def filter_by_timestamp_conditions
    timestamp = params[:timestamp]

    return "" unless timestamp.present?

    timelines = Arel::Table.new(:timelines)
    timelines[:published_at].lteq(timestamp).to_sql
  end

  def filter_by_exclude_types_conditions
    collection = params.fetch(:exclude_feed_types, [])

    return "" unless collection.present?

    timelines = Arel::Table.new(:timelines)
    timelines[:feed_type].not_in(collection).to_sql
  end

  def filter_by_user_id_conditions
    collection = Array(params[:facebook_user_id])

    return "" unless collection.present?

    timelines = Arel::Table.new(:timeline_publishers)
    timelines[:user_identifier].in(collection).to_sql
  end

  def filter_by_current_user_id_conditions
    return "" unless params[:my].present?

    timelines = Arel::Table.new(:timeline_publishers)
    timelines[:user_identifier].in([user.facebook_id]).to_sql
  end

end

TimelinesCollection::PerPage = 50
