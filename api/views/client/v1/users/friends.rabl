collection @friends
attributes :id, :email, :name, :facebook_profile_image_url, :facebook_id, :username, :followers_count,
            :followed_count, :friends_count, :ext_id, :profile_image

node(:user_timelines_count) { |user| user.timelines_count }
node(:is_followed) {  true }