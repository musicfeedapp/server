# -*- coding: utf-8 -*-
require 'spec_helper'

module Aggregator
  module Search

    TestSoundcloudSearch = Struct.new(:soundcloud_id) do
      include Aggregator::Search::SoundcloudSearch
    end

    describe SoundcloudSearch do
      let(:soundcloud_id) { "https://soundcloud.com/david-gohlki/leftalone" }

      it 'should be possible to find soundcloud track by id' do
        instance = TestSoundcloudSearch.new(soundcloud_id)
        expect(instance.track).to be
        expect(instance.track.name).to eq("- Left Alone -")
        expect(instance.track.artist).to eq("Gohlki")
        expect(instance.track.picture).to eq("https://i1.sndcdn.com/artworks-000131636170-xuhuf5-t500x500.jpg")
      end
    end

  end
end
