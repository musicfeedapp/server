# -*- coding: utf-8 -*-
require 'spec_helper'

module Aggregator
  module Search

    TestSpotifySearch = Struct.new(:spotify_id) do
      include Aggregator::Search::SpotifySearch
    end


    describe SpotifySearch do
      let(:spotify_id) { "1301WleyT98MSxVHPZCA6M" }

      it 'should be possible to find spotify track by id' do
        instance = TestSpotifySearch.new(spotify_id)
        expect(instance.track).to be
        expect(instance.track.name).to eq("Sonata No. 2, Op. 35, in B-Flat Minor: Grave; Doppio movimento")
        expect(instance.track.artist).to eq("Frédéric Chopin")
        expect(instance.track.picture).to eq("https://i.scdn.co/image/6b262f7de37557be1722b55604def3bff99ae261")
      end
    end

  end
end
