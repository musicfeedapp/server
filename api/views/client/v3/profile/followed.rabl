object @user
node(:followed) do |user|
  user.followers.values.flatten.map do |node|
    partial('v1/profile/followed', object: node)
  end
end