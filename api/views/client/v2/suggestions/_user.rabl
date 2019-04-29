attributes :id, :facebook_id, :facebook_link, :twitter_link,
  :name, :username, :ext_id, :is_verified_user, :user_follower_count

node(:avatar_url) { |user| user.profile_image }
node(:identifier) { |user| user.identifier }
node(:is_followed) { |user| false }
node(:genres) { |user| user.genres.pluck("name") }

node(:timelines) { [] }
node(:common_followers) { [] }

