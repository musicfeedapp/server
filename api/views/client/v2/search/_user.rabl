attributes :id, :facebook_id, :facebook_link, :twitter_link, :username, :ext_id,
  :is_followed, :is_verified

node(:name) { |user| user.name }
node(:avatar_url) { |user| user.profile_image }
node(:identifier) { |user| user.id }
node(:tracks_count) { |user| user.timelines_count }
