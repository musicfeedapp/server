attribute :name, :email, :authentication_token, :first_name, :last_name,
  :background, :username, :ext_id, :is_verified, :contact_number,
  :secondary_emails, :secondary_phones, :profile_image, :login_method

node(:avatar_url)           { |user| user.profile_image }
node(:is_followed)          { |user| user.is_followed? }
node(:playlists_count)      { |user| user.playlists_count }
node(:songs_count)          { |user| user.songs_count }
node(:followings_count)     { |user| user.followings_count }
node(:followed_count)       { |user| user.followers_count }
node(:facebook_link)        { |user| user.facebook_link }
node(:facebook_id)          { |user| user.identifier }
node(:is_facebook_expired)  { |user| user.is_facebook_expired? }
node(:is_artist)            { |user| user.artist? }
