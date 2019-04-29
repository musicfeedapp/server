collection @artists

attributes :id, :facebook_id, :facebook_link, :twitter_link,
 :name, :username, :ext_id, :followed_at

node(:genres) { |artist| artist.genres_names }

node(:avatar_url) { |user| user.profile_image }
node(:identifier) { |user| user.identifier }
node(:is_followed) { |user| false }
