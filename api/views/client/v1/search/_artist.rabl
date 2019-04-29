attributes :id, :facebook_id, :facebook_link, :twitter_link,
  :name, :username, :ext_id

node(:identifier) { |artist| artist.identifier }
node(:avatar_url) { |artist| artist.profile_image }
node(:genres)     { |artist| artist.genres.pluck("name") }