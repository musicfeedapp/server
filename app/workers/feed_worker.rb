class FeedWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :heavy, :retry => false, :unique => :while_executing

  class NodeWorker
    include Sidekiq::Worker

    sidekiq_options :queue => :heavy, :retry => false, :unique => :while_executing

    # tc = timelines collection
    def perform(user_id)
      user = User.find(user_id)

      # ps = pages
      if (pages = Cache.get("tc:#{user.facebook_id}:ps")).present?
        puts "=========== Start clear pages"

        JSON.parse(pages).each do |page|
          Cache.remove("tc:#{user.facebook_id}:#{page}")
        end

        puts "=========== Done clear pages"
      end

      pages = []

      puts "=========== Start page 1"
      # page 1
      timelines_collection = TimelinesCollection.new(user, {})
      timelines, _comments, _activities = timelines_collection.find(only_timelines: true)
      Cache.set("tc:#{user.facebook_id}:", timelines.map(&:id).to_json)
      puts "=========== Done page 1"

      1.times do |i|
        if (last_timeline_id = timelines.last.try(:id)).present?
          puts "=========== Start page #{i + 2}"

          pages << last_timeline_id

          timelines_collection = TimelinesCollection.new(user, last_timeline_id: last_timeline_id)
          timelines, _comments, _activities = timelines_collection.find(only_timelines: true)
          Cache.set("tc:#{user.facebook_id}:#{last_timeline_id}", timelines.map(&:id).to_json)

          puts "=========== Done page #{i + 2}"
        end
      end

      Cache.set("tc:#{user.facebook_id}:ps", pages.to_json)
    end
  end

  def perform()
    User.user.select('id').all.each do |user|
      NodeWorker.perform_async(user.id)
    end
  end
end
