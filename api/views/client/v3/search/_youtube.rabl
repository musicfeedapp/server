attributes :name, :link, :picture, :feed_type, :author, :author_picture,
  :user_identifier, :album, :artist, :youtube_link,
  :is_liked, :font_color, :source_link, :author_ext_id, :is_verified_user,
  :stream

node(:id) { |timeline| timeline.generated_id }
node(:author_identifier) { |user| user.user_identifier }
node(:username) { |timeline| timeline.author }
node(:comments_count) { |timeline| timeline.comments_count }
node(:published_at) { |timeline| timeline.published_at.as_json }
node(:likes_count) { |timeline| timeline.likes_count.to_i }
