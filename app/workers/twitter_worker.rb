class TwitterWorker
  include Sidekiq::Worker

  def perform
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = "4BXNQnxPfGutiTooy5Mw9jfv3"
      config.consumer_secret     = "GLwRjJ5oYmCUe7yZbM4gxqJdv2EJ9micxZz4aY70XokycCqS8E"
      config.access_token        = "2937070402-eb1SbQRWjsSWLsE3PqxcoGsHRnmBSMbXZUQRpDt"
      config.access_token_secret = "sCHYKS6VI9EkRxGrLxaHZDvgOgDJFTTdo1QUY0bJLOb2g"
    end

    published_timeline_id = Rails.cache.read('published_timeline_id')

    timeline = Timeline.find_by_sql("
      SELECT
        timelines.*,
        tp.created_at AS last_feed_appearance_timestamp,
        (
          SELECT
            (SELECT COUNT(t1.id) FROM timeline_publishers t1 WHERE t1.timeline_id=timelines.id AND t1.updated_at >= current_date - interval '1' day) +
            (SELECT COUNT(t1.id) FROM user_likes t1 WHERE t1.timeline_id=timelines.id AND t1.updated_at >= current_date - interval '1' day)
        ) AS counter
      FROM timelines
      INNER JOIN timeline_publishers tp ON tp.timeline_id=timelines.id
      WHERE tp.created_at >= current_date - interval '1' day and timelines.id != #{published_timeline_id}
      ORDER BY
        counter DESC NULLS LAST,
        view_count DESC NULLS LAST,
        last_feed_appearance_timestamp DESC
      LIMIT 1
    ".squish)

    t = timeline.first
    return unless t

    Rails.cache.write('published_timeline_id', t.id)

    title = "Listen to "

    link = t.link
    if t.feed_type == Timeline::TYPES[:youtube]
      link = "https://www.youtube.com/watch?v=#{t.youtube_id}"
    end

    tags1 = "#trackoftheday"
    tags2 = "#music"

    if link.size >= 140
      message = link
      client.update(message)
      return
    end

    if title.size + link.size + 1 >= 140
      message = link
      client.update(message)
      return
    end

    if title.size + link.size + t.name.to_s.size + 1 >= 140
      message = "#{title}#{link}"
      client.update(message)
      return
    end

    if title.size + link.size + t.name.to_s.size + t.artist.to_s.size + 1 >= 140
      message = "#{title} #{t.name} #{link}"
      client.update(message)
      return
    end

    if title.size + link.size + 1 + t.name.to_s.size + t.artist.to_s.size + tags1.size + 1 >= 140
      message = "#{title} #{t.name} by #{t.artist} #{link}"
      client.update(message)
      return
    end

    if title.size + link.size + 1 + t.name.to_s.size + t.artist.to_s.size + tags1.size + tags2.size + 1 >= 140
      message = "#{title} #{t.name} by #{t.artist} #{tags1} #{link}"
      client.update(message)
      return
    end

    message = "#{title} #{t.name} by #{t.artist} #{tags1} #{tags2} #{link}"
    client.update(message)
  end
end
