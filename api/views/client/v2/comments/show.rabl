object @comment
attributes :id, :comment, :created_at

node(:eventable_type) { |comment| comment.eventable_type }
node(:eventable_id) { |comment| comment.eventable_id }

node(:user_name) { |comment| comment.user.try(:name) }
node(:user_facebook_id) { |comment| comment.user.try(:facebook_id) }
node(:user_avatar_url) { |comment| "http://graph.facebook.com/#{comment.user.facebook_id}/picture?type=normal" }
node(:user_ext_id) { |comment| comment.user.try(:ext_id) }
