object @timeline

attributes :name, :link, :picture, :feed_type,
  :album, :artist, :youtube_link, :font_color, :source_link,
  :itunes_link, :stream, :is_posted

node(:id) { |timeline| timeline.id || timeline.custom_id }
node(:is_liked) { false }
node(:is_verified_user) { current_user.is_verified }
node(:author_is_followed) { false }
node(:author_ext_id) { current_user.ext_id }
node(:author) { current_user.name }
node(:author_picture) { current_user.profile_image }
node(:author_identifier) { current_user.identifier }
node(:author_name) { current_user.name }
node(:username) { |timeline| current_user.name }
node(:comments_count) { |timeline| timeline.comments_count }
node(:published_at) { |timeline| timeline.published_at.as_json }
node(:likes_count) { |timeline| timeline.likes_count.to_i }
