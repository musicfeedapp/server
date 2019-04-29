require 'spec_helper'

module Aggregator
  module Recognize

    describe Spotify do
      it 'should skip find shazam timeline by url' do
        timeline = Spotify.new("Eminem", "Stan")
        expect(timeline.valid?).to eq(true)
        expect(timeline.artist).to eq("Eminem")
        expect(timeline.name).to eq("Stan")
        expect(timeline.spotify_id).to eq("4QVOTT9CM2ftSLwnYGNDjd")
        expect(timeline.spotify_url).to eq("spotify:track:4QVOTT9CM2ftSLwnYGNDjd")
        expect(timeline.picture).to eq("https://i.scdn.co/image/431f5d17450726d5f75435e272ee74834dbbed44")
      end
    end

  end
end


