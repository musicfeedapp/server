node(:artists) {
  @artists.map do |node|
    partial('v2/suggestions/user', object: node)
  end
}

node(:users) {
  @users.map do |node|
    partial('v2/suggestions/user', object: node)
  end
}

node(:trending_artists) {
  @trending_artists.map do |node|
    partial('v2/suggestions/user', object: node)
  end
}

