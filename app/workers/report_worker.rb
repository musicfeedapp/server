class ReportWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :heavy, :retry => false, :unique => :while_executing

  def perform
    stats =
      {
        timelines: {
          total: Timeline.count,
          yesterday_today: Timeline.where(created_at: Date.yesterday..1.day.from_now.to_date).count,
          seven_days: Timeline.where(created_at: 7.days.ago.to_date..1.day.from_now.to_date).count,
        },
        users: {
          total: User.user.count,
          yesterday_today: User.user.where(created_at: Date.yesterday..1.day.from_now.to_date).count,
          seven_days: User.user.where(created_at: 7.days.ago.to_date..1.day.from_now.to_date).count,
        },
        artists: {
          total: User.artist.count,
          facebook_artists: User.artist.where(is_verified: false).count,
          facebook_artists_seven_days: User.artist.where(created_at: Date.yesterday..1.day.from_now.to_date).where(is_verified: false).count,
          verified_artists: User.artist.where(is_verified: true).count,
          verified_artists_seven_days: User.artist.where(created_at: Date.yesterday..1.day.from_now.to_date).where(is_verified: true).count,
          yesterday_today: User.artist.where(created_at: Date.yesterday..1.day.from_now.to_date).count,
          seven_days: User.artist.where(created_at: 7.days.ago.to_date..1.day.from_now.to_date).count,
        },
        total: {
          timelines: Timeline.count,
          users: User.user.count,
          artists: User.artist.count,
          artists_verified: User.artist.where(is_verified: true).count,
        },
        music: {
          youtube: Timeline.youtube.count,
          spotify: Timeline.spotify.count,
          soundcloud: Timeline.soundcloud.count,
          shazam: Timeline.shazam.count,
          mixcloud: Timeline.mixcloud.count,
          total: Timeline.count.zero? ? 1 : Timeline.count,
        }
      }

    stats.each do |k1, v1|
      v1.each do |k2, v2|
        $redis.set("dashboard:#{k1}:#{k2}", v2)
      end
    end

    recent_ids = Timeline.where(created_at: Date.yesterday..1.day.from_now.to_date).pluck(:id)
    $redis.set("dashboard:timelines:recent", recent_ids.to_json)

    recent_ids = User.where(created_at: Date.yesterday..1.day.from_now.to_date).pluck(:id)
    $redis.set("dashboard:artists:recent", recent_ids.to_json)
  end
end
