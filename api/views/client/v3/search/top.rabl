node(:top_artists) {
  @top_artists.map do |node|
    partial('v3/search/artist', object: node)
  end
}

node(:top_users) {
  @top_users.map do |node|
    partial('v3/search/user', object: node)
  end
}

node(:top_timelines) {
  @top_timelines.map do |node|
    partial('v3/search/timeline', object: node)
  end
}
