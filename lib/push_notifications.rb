module PushNotifications
  class Worker
    include Sidekiq::Worker

    sidekiq_options :queue => :push_notifications, :retry => 2, :unique => :while_executing

    def perform(method_name, arguments)
      PushNotifications.send(method_name, *arguments)
    end
  end

  TRACK_POSTED = "%s posted your track '%s' on Musicfeed."
  def track_posted(user_id, timeline_id)
    user = User.find(user_id)
    timeline = Timeline.find(timeline_id)

    timeline.publishers.each do |who|
      next if user.id == who.id

      data = {
        :alert => TRACK_POSTED % [user.name, timeline.name],
        :ext_id => who.ext_id,
        :event_type => 'track_posted',
        :to_user_id => who.ext_id,
      }

      UserNotification.create(to_user_id: who.id, from_user_id: user.id, alert_type: "track_posted", timeline_id: timeline.id)
      query = Parse::Query.new(Parse::Protocol::CLASS_INSTALLATION).eq('userExtId', who.ext_id)

      push = Parse::Push.new(data)
      push.where = query.where
      push.save
    end
  end
  module_function :track_posted

  FRIEND_TEMPLATE = "%s is now on Musicfeed."
  def friend_joined(who_id, user_ids)
    who = User.find(who_id)
    users = User.where(facebook_id: user_ids)
    users.each do |user|
      data = {
              :alert => FRIEND_TEMPLATE % who.name,
              :ext_id => who.ext_id,
              :event_type => 'user_joined',
              :to_user_id => user.ext_id,
             }

      UserNotification.create(to_user_id: user.id, from_user_id: who_id, alert_type: "user_joined")
      query = Parse::Query.new(Parse::Protocol::CLASS_INSTALLATION).eq('userExtId', user.ext_id)

      push = Parse::Push.new(data)
      push.where = query.where
      push.save
    end
  end
  module_function :friend_joined

  ARTIST_ADDED_TEMPLATE = "%s artists are added to Musicfeed."
  def artist_added(who_id, artist_ids)
    return if artist_ids.size == 0

    who = User.find(who_id)
    data = {
            :alert => ARTIST_ADDED_TEMPLATE % artist_ids.size.to_s,
            :ext_id => "",
            :event_type => 'artist_added',
            :to_user_id => who.ext_id,
           }

    UserNotification.create(to_user_id: who.id, artist_ids: artist_ids, alert_type: "artist_added")
    query = Parse::Query.new(Parse::Protocol::CLASS_INSTALLATION).eq('userExtId', who.ext_id)

    push = Parse::Push.new(data)
    push.where = query.where
    push.save
  end
  module_function :artist_added


  FOLLOW_TEMPLATE = "%s is now following you."
  def follow(who_id, user_id)
    return if who_id == user_id

    who = User.find(who_id)
    user = User.find(user_id)

    data = {
            :alert => FOLLOW_TEMPLATE % who.name,
            :ext_id => who.ext_id,
            :event_type => 'follow',
            :to_user_id => user.ext_id,
           }

    UserNotification.create(to_user_id: user_id, from_user_id: who_id, alert_type: "follow")
    query = Parse::Query.new(Parse::Protocol::CLASS_INSTALLATION).eq('userExtId', user.ext_id)

    push = Parse::Push.new(data)
    push.where = query.where
    push.save
  end
  module_function :follow

  LIKE_TEMPLATE = "%s liked your post '%s'"
  def like(who_id, timeline_id)
    who = User.find(who_id)
    timeline = Timeline.find(timeline_id)

    timeline.publishers.each do |owner|
      next if owner.id == who.id

      data = {
        :alert => LIKE_TEMPLATE % [who.name, timeline.name],
        :track_id => timeline_id,
        :event_type => 'like'
      }
      UserNotification.create(to_user_id: owner.id, from_user_id: who_id, alert_type: "like", timeline_id: timeline_id)
      query = Parse::Query.new(Parse::Protocol::CLASS_INSTALLATION).eq('userExtId', owner.ext_id)

      push = Parse::Push.new(data)
      push.where = query.where
      push.save
    end
  end
  module_function :like

  PLAYLIST_ADD_TEMPLATE = "%s added your post '%s' to the playlist '%s'"
  def add_timeline_to_playlist(who_id, playlist_id, timeline_id)
    who = User.find(who_id) # will raise error for who_id
    playlist = Playlist.find(playlist_id)
    timeline = Timeline.find(timeline_id)

    timeline.publishers.each do |owner|
      next if owner == who

      data = {
        :alert => PLAYLIST_ADD_TEMPLATE % [who.name, timeline.name, playlist.title],
        :track_id => timeline_id,
        :event_type => 'add_to_playlist',
        :playlist_id => playlist_id,
        :user_ext_id => who.ext_id
      }
      UserNotification.create(to_user_id: owner.id, from_user_id: who_id, alert_type: "add_to_playlist", timeline_id: timeline_id, playlist_id: playlist_id)
      query = Parse::Query.new(Parse::Protocol::CLASS_INSTALLATION).eq('userExtId', owner.ext_id)

      push = Parse::Push.new(data)
      push.where = query.where
      push.save
    end
  end
  module_function :add_timeline_to_playlist

  ADD_COMMENT_TEMPLATE = "%s commented on your post '%s' '%s'"
  def add_comment(who_id, comment_id, timeline_id)
    who = User.find(who_id)
    comment = Comment.find(comment_id)
    timeline = Timeline.find(timeline_id)

    timeline.publishers.each do |owner|
      next if who.id == owner.id

      data = {
        :alert => ADD_COMMENT_TEMPLATE % [who.name, timeline.name, comment.comment.to_s.truncate(33, separator: /\s/)],
        :track_id => timeline.id,
        :event_type => 'add_comment',
        :comment_id => comment_id
      }
      UserNotification.create(to_user_id: owner.id, from_user_id: who_id, alert_type: "add_comment", timeline_id: timeline_id, comment_id: comment_id, message: comment.comment.to_s.truncate(33, separator: /\s/))
      query = Parse::Query.new(Parse::Protocol::CLASS_INSTALLATION).eq('userExtId', owner.ext_id)

      push = Parse::Push.new(data)
      push.where = query.where
      push.save
    end
  end
  module_function :add_comment

  def feed_count(user_id, feed_count)
    user = User.find(user_id)

    data = {
      :ext_id => user.ext_id,
      :event_type => 'feed_count',
      :to_user_id => user.ext_id,
      :count => feed_count,
      :badge => feed_count
    }

    query = Parse::Query.new(Parse::Protocol::CLASS_INSTALLATION).eq('userExtId', user.ext_id)
    push = Parse::Push.new(data)
    push.where = query.where
    push.save
  end
  module_function :feed_count
end
