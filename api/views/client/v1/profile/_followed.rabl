attributes :facebook_id, :username, :ext_id, :is_verified

node(:picture) { |user| user.profile_image }
node(:title) { |user| user.name }
node(:timelines_count) { |user| user.songs_count }
node(:is_followed) { |user| user.is_followed? }
