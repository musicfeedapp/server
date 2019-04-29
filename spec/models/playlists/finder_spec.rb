require 'spec_helper'

module Playlists

  describe Finder do
    it 'should find playlists by id' do
      instance = Finder.find_by_id('default') { |klass| playlists = klass.new(User.new) }
      expect(instance.is_a?(Default)).to eq(true)

      instance = Finder.find_by_id('likes') { |klass| klass.new(User.new) }
      expect(instance.is_a?(Likes)).to eq(true)

      instance = Finder.find_by_id('nothing') { |klass| klass.new(User.new) }
      expect(instance.nil?).to eq(true)

      playlist = create(:playlist)
      instance = Finder.find_by_id(playlist.id)
      expect(instance).to eq(playlist)
    end
  end

end
