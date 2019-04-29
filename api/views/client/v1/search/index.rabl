node(:artists) {
  @collections[:artists].map do |node|
    partial('v1/search/artist', object: node)
  end
}

node(:users) {
  @collections[:users].map do |node|
    partial('v1/search/user', object: node)
  end
}
