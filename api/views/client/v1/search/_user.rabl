attributes :id, :facebook_id, :facebook_link, :twitter_link, :username, :ext_id

node(:name) { |user| user.name }
node(:avatar_url) { |user| user.profile_image }
node(:identifier) { |user| user.id }
