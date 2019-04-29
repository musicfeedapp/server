require Rails.root.join('app/workers/facebook')
require Rails.root.join('app/workers/facebook/feed')
require Rails.root.join('app/workers/facebook/feed/hourly_artist_worker')
require Rails.root.join('app/workers/facebook/feed/artist_worker')

namespace :jobs do

  task :ping => :environment do
    PingWorker.perform_async
    $redis.set("jobs:ping", DateTime.now.to_s(:db))
  end

  task :dashboard => :environment do
    ReportWorker.new.perform
  end

  namespace :artists do
    task :hourly => :environment do
      Facebook::Feed::HourlyArtistWorker.new.perform
    end

    task :daily => :environment do
      Facebook::Feed::ArtistWorker.new.perform
    end
  end

  task :missing_categories => :environment do
    NewMissingCategoriesWorker.perform_async
    $redis.set("jobs:categories:missing", DateTime.now.to_s(:db))
  end

  task :feed_counter => :environment do
    UpdateFeedAppIconCountWorker.perform_async
    $redis.set("jobs:feed:counter", DateTime.now.to_s(:db))
  end

  task :views => :environment do
    Suggestions.refresh
    $redis.set("jobs:suggestions:views", DateTime.now.to_s(:db))
  end

  task :feed => :environment do
    FeedWorker.perform_async
  end

  task :twitter => :environment do
    TwitterWorker.new.perform
  end
end
