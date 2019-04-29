require 'spec_helper'

describe UserGenre do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
#
# Table name: user_genres
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  genre_id   :integer
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_user_genres_on_genre_id              (genre_id)
#  index_user_genres_on_user_id               (user_id)
#  index_user_genres_on_user_id_and_genre_id  (user_id,genre_id) UNIQUE
#
