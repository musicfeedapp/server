class DashboardController < ApplicationController
  def index
    @dashboard = Dashboard.new
  end

  class Dashboard
    def recent
      @recent ||= begin
                    timelines_ids = $redis.get("dashboard:timelines:recent") || "[]"
                    Timeline
                      .where(id: JSON.parse(timelines_ids))
                      .eager_load(:publishers)
                      .limit(200)
                  end
    end

    def recent_artists
      @recent_artists ||= begin
                    ids = $redis.get("dashboard:artists:recent") || "[]"
                    User.where(id: JSON.parse(ids))
                  end
    end

    def workers
      @workers ||= {
        artists: {
          daily: {
            time: $redis.get("ws:as:tm"),
            progress: $redis.get("ws:as:pg"),
            done: $redis.get("ws:as:in") != "true",
          },
          hourly: {
            time: $redis.get("ws:ha:tm"),
            progress: $redis.get("ws:ha:pg"),
            done: $redis.get("ws:ha:in") != "true",
          }
        }
      }
    end

    def stats
      @stats ||= begin
                   s = {
                     timelines: {
                       total: 0,
                       yesterday_today: 0,
                       seven_days: 0,
                     },
                     users: {
                       total: 0,
                       yesterday_today: 0,
                       seven_days: 0,
                     },
                     artists: {
                       total: 0,
                       verified_artists: 0,
                       verified_artists_seven_days: 0,
                       facebook_artists: 0,
                       facebook_artists_seven_days: 0,
                       yesterday_today: 0,
                       seven_days: 0,
                     },
                     total: {
                       timelines: 0,
                       users: 0,
                       artists: 0,
                       artists_verified: 0,
                     },
                     music: {
                       youtube: 0,
                       spotify: 0,
                       soundcloud: 0,
                       shazam: 0,
                       mixcloud: 0,
                       total: 1,
                     }
                   }

                   s.each do |k1, v1|
                     v1.each do |k2, v2|
                       if k2 == :total
                         s[k1][k2] = $redis.get("dashboard:#{k1}:#{k2}") || 1
                       else
                         s[k1][k2] = $redis.get("dashboard:#{k1}:#{k2}") || 0
                       end
                     end
                   end

                   s
                 end
    end
  end
end
