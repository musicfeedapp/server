require 'spec_helper'

describe User do

  describe '#create_genres!' do
    it "should create genres from genres name array" do
      names = []
      10.times { names << rand(36**10).to_s(36) }

      Genre.create_genres!(names)

      expect(Genre.count).to eq(10)
    end

    it "should work fine in case of no genres on pass" do
      names = []

      genres = Genre.create_genres!(names)

      expect(genres.empty?).to eq(true)
      expect(Genre.count).to eq(0)
    end

    it "should should skip the duplicates" do
      genre  = create(:genre)
      genres = Genre.create_genres!([ "Hypnotize", "trance"])

      expect(genres.count).to eq(1)
    end
  end

  describe "#create_user_genre!" do
    it "should map specific genres against the current user" do
      user       = create(:user)
      genres     = Genre.create_genres!([ "Hypnotize", "trance"])
      genres_ids = genres.map{ |hash| hash["id"] }

      user.create_user_genre!(genres_ids)

      expect(user.genres.count).to eq(2)
      expect(user.user_genres.count).to eq(2)
    end

    it "should delete previous genres and update with new ones" do
      user       = create(:user)
      genres     = Genre.create_genres!([ "Hypnotize", "trance"])
      genres_ids = genres.map{ |hash| hash["id"] }

      user.create_user_genre!(genres_ids)

      expect(user.genres.count).to eq(2)
      expect(user.user_genres.count).to eq(2)

      user.create_user_genre!([ genres_ids.first ])

      expect(user.genres.count).to eq(1)
      expect(user.user_genres.count).to eq(1)
    end
  end
end
