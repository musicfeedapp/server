collection @playlists

node(:id) { |instance| instance.id }
node(:title) { |instance| instance.title }
node(:tracks_count) { |instance| instance.tracks_count }
node(:picture_url) { |instance| instance.picture_url }
node(:is_private) { |instance| instance.is_private }
