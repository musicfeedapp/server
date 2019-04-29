collection @notifications
attributes :id, :alert_type, :created_at

node(:status) { |notification| notification.status.downcase }

child :timeline, if: lambda {|notifications| notifications.related_to_timeline? } do 
  attributes :id, :name
end

child :sender do 
  attributes :id, :name, :profile_image, :ext_id
end

child :playlist, if: lambda {|notifications| notifications.alert_type == "add_to_playlist" } do 
  attributes :id, :title
end

child :comment, if: lambda {|notifications| notifications.alert_type == "add_comment" } do 
  attributes :id, :comment
end

node(:artists_count, if: lambda { |notifications| notifications.alert_type == "artist_added" }) do |notification|
  notification.artist_ids.size
end

node(:recently_added_artists, if: lambda { |notifications| notifications.alert_type == "artist_added" }) do |notification|
  User.where(id: notification.artist_ids).each do |node|
    partial('v1/search/artist', object: node)
  end
end