node(:artists) {
  @artists.map do |node|
    partial('v3/search/artist', object: node)
  end
}

node(:users) {
  @users.map do |node|
    partial('v3/search/user', object: node)
  end
}

node(:timelines) {
  @timelines.map do |node|
    partial('v3/search/timeline', object: node)
  end
}

node(:playlists) {
  @playlists.map do |node|
    partial('v3/search/playlist', object: node)
  end
}

node(:youtubes) {
  @youtubes.map do |node|
    partial('v3/search/youtube', object: node)
  end
}

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
