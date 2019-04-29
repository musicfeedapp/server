attributes :id, :name, :link, :picture, :feed_type,
  :album, :artist, :youtube_link,
  :is_liked, :font_color, :source_link,
  :itunes_link, :stream,
  :last_feed_appearance_timestamp

node(:author) { |timeline| locals[:publishers][timeline.id][0].author }
node(:author_name) { |timeline| locals[:publishers][timeline.id][0].author_name }
node(:author_picture) { |timeline| locals[:publishers][timeline.id][0].author_picture }
node(:author_identifier) { |timeline| locals[:publishers][timeline.id][0].author_identifier }
node(:author_is_followed) { |timeline| locals[:publishers][timeline.id][0].author_is_followed }
node(:user_identifier) { |timeline| locals[:publishers][timeline.id][0].user_identifier }
node(:author_ext_id) { |timeline| locals[:publishers][timeline.id][0].author_ext_id }
node(:username) { |timeline| locals[:publishers][timeline.id][0].username }
node(:is_verified_user) { |timeline| locals[:publishers][timeline.id][0].is_verified_user }

node(:last_activity_eventable_type) { |timeline| locals[:activities][timeline.id][0].last_activity_eventable_type }
node(:last_activity_created_at) { |timeline| locals[:activities][timeline.id][0].last_activity_created_at }

node(:comments_count) { |timeline| timeline.comments_count }
node(:published_at) { |timeline| timeline.published_at.as_json }
node(:likes_count) { |timeline| timeline.likes_count.to_i }
