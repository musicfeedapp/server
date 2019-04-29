object @user
node(:followings) do |user|
  {}.tap do |view|
    user.followings.tap do |followings|
      view[:artists] = followings[:artists].map do |node|
        partial('v1/profile/following', object: node)
      end

      view[:friends] = followings[:friends].map do |node|
        partial('v1/profile/following', object: node)
      end
    end
  end
end