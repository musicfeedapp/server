attributes :id, :facebook_id, :facebook_link, :twitter_link,
  :name, :username, :ext_id, :is_verified_user, :user_follower_count

node(:avatar_url) { |user| user.profile_image }
node(:identifier) { |user| user.identifier }
node(:is_followed) { |user| false }
node(:genres) { |artist| artist.genres_names }

node(:timelines) do |user|
  partial('v5/suggestions/timelines', object: locals[:timelines][user.id], locals: { publishers: locals[:publishers], activities: locals[:activities] })
end

node(:common_followers) do |user|
  @common_followers[user.id].map do |user|
    partial('v3/search/_user', object: user, locals: { user: user })
  end
end
