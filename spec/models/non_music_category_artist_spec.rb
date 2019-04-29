require 'spec_helper'

describe NonMusicCategoryArtist do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
#
# Table name: non_music_category_artists
#
#  id                                :integer          not null, primary key
#  email                             :string
#  encrypted_password                :string
#  reset_password_token              :string
#  reset_password_sent_at            :datetime
#  remember_created_at               :datetime
#  sign_in_count                     :integer          default(0)
#  current_sign_in_at                :datetime
#  last_sign_in_at                   :datetime
#  current_sign_in_ip                :string
#  last_sign_in_ip                   :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  role                              :string
#  avatar                            :string
#  first_name                        :string
#  middle_name                       :string
#  last_name                         :string
#  facebook_link                     :string
#  twitter_link                      :string
#  google_plus_link                  :string
#  linkedin_link                     :string
#  facebook_avatar                   :string
#  google_plus_avatar                :string
#  linkedin_avatar                   :string
#  authentication_token              :string
#  facebook_profile_image_url        :string
#  facebook_id                       :string
#  background                        :string
#  username                          :string
#  comments_count                    :integer          default(0)
#  enabled                           :boolean          default(TRUE)
#  likes_count                       :integer          default(0)
#  website                           :text             default("0")
#  genres                            :text
#  user_type                         :string
#  followers_count                   :integer
#  followed_count                    :integer
#  friends_count                     :integer
#  user_timelines_count              :integer          default(0)
#  artist_timelines_count            :integer          default(0)
#  name                              :string
#  is_verified                       :boolean          default(FALSE)
#  ext_id                            :string
#  restricted_timelines              :integer          default([]), is an Array
#  restricted_users                  :string           default([]), is an Array
#  authenticated                     :boolean          default(FALSE)
#  category                          :string
#  public_playlists_timelines_count  :integer          default(0)
#  private_playlists_timelines_count :integer          default(0)
#  welcome_notified_at               :datetime
#  aggregated_at                     :datetime
#  facebook_exception                :text
#  suggestions_count                 :integer
#
