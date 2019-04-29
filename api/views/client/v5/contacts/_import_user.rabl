attributes :id, :facebook_id, :facebook_link, :twitter_link, :username, :ext_id, :name, :followed_at,
  :is_verified, :is_followed

node(:genres) { |artist| artist.genres_names }
node(:avatar_url) { |user| user.profile_image }
node(:identifier) { |user| user.id }
node(:tracks_count) { |user| user.timelines_count }
node(:is_followed) { |user| user.is_followed }
