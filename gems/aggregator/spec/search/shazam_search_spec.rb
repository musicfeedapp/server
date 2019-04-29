# -*- coding: utf-8 -*-
require 'spec_helper'

module Aggregator
  module Search
    TestShazamSearch = Struct.new(:shazam_id) do
      include Aggregator::Search::ShazamSearch
    end

    describe ShazamSearch do
      let(:shazam_id) { "http://www.shazam.com/track/119138723/like-i-can" }

      it 'should be possible to find shazam track by id' do
        instance = TestShazamSearch.new(shazam_id)
        expect(instance.track).to be
        expect(instance.track.name).to eq("Sam Smith - Like I Can")
        expect(instance.track.artist).to eq("Sam Smith")
        expect(instance.track.picture).to eq("http://images.shazam.com/coverart/t119138723-i836166483_s400.jpg")
      end
    end

  end
end
