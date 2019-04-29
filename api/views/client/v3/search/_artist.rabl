attributes :id, :facebook_id, :facebook_link, :twitter_link,
  :name, :username, :ext_id, :is_verified, :is_followed

node(:identifier) { |artist| artist.identifier }
node(:avatar_url) { |artist| artist.profile_image }
node(:tracks_count) { |user| user.timelines_count }
node(:genres) { |artist| artist.genres_names }
