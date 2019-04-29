node(:artists) {
  @artists.map do |node|
    partial('v2/search/artist', object: node)
  end
}

node(:users) {
  @users.map do |node|
    partial('v2/search/user', object: node)
  end
}

node(:timelines) {
  @timelines.map do |node|
    partial('v2/search/timeline', object: node)
  end
}

node(:playlists) {
  @playlists.map do |node|
    partial('v2/search/playlist', object: node)
  end
}
