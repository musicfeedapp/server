node(:artists) {
  @artists.map do |node|
    partial('v5/contacts/import_user', object: node)
  end
}