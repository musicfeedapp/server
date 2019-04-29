collection @timelines

attributes :id, :name, :link, :picture, :feed_type,
  :album, :artist, :youtube_link,
  :is_liked, :font_color, :source_link,
  :itunes_link, :stream

node(:last_feed_appearance_timestamp) { |timeline| timeline[:last_feed_appearance_timestamp] }
node(:author) { |timeline| @publishers[timeline.id][0].author }
node(:author_name) { |timeline| @publishers[timeline.id][0].author_name }
node(:author_picture) { |timeline| @publishers[timeline.id][0].author_picture }
node(:author_identifier) { |timeline| @publishers[timeline.id][0].author_identifier }
node(:author_is_followed) { |timeline| @publishers[timeline.id][0].author_is_followed }
node(:user_identifier) { |timeline| @publishers[timeline.id][0].user_identifier }
node(:author_ext_id) { |timeline| @publishers[timeline.id][0].author_ext_id }
node(:username) { |timeline| @publishers[timeline.id][0].username }
node(:is_verified_user) { |timeline| @publishers[timeline.id][0].is_verified_user }

node(:last_activity_eventable_type) do |timeline|
  if @activities[timeline.id].present? && @activities[timeline.id][0].present?
    @activities[timeline.id][0].last_activity_eventable_type
  end
end

node(:last_activity_created_at) do |timeline|
  if @activities[timeline.id].present? && @activities[timeline.id][0].present?
    @activities[timeline.id][0].last_activity_created_at
  end
end

node(:comments_count) { |timeline| timeline.comments_count }
node(:published_at) { |timeline| timeline.published_at.as_json }
node(:likes_count) { |timeline| timeline.likes_count.to_i }
