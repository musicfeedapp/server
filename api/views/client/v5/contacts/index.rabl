node(:users) {
  @users.map do |node|
    partial('v5/contacts/import_user', object: node)
  end
}