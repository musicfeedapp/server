attribute :name, :email, :authentication_token, :first_name, :last_name,
  :avatar_url, :background, :username, :profile_image, :ext_id, :is_verified

node(:followed) do |user|
  user.followers.values.flatten.map do |node|
    partial('v1/profile/followed', object: node)
  end
end

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

node(:songs) do |user|
#   timelines, activities, publishers = user.songs

#  timelines.map do |timeline|
#    partial('v1/profile/song', object: timeline, locals: { publishers: publishers, activities: activities })
#  end
end

node(:playlists) do |user|
  user.playlists.map do |node|
    partial('v1/playlists/playlist', object: node)
  end
end

node(:is_followed)          { |user| user.is_followed? }
node(:songs_count)          { |user| user.songs_count }
node(:followings_count)     { |user| user.followings_count }
node(:followed_count)       { |user| user.followers_count }

node(:facebook_link)        { |user| user.facebook_link }
node(:facebook_id)          { |user| user.identifier }
node(:is_facebook_expired)  { |user| user.is_facebook_expired? }
