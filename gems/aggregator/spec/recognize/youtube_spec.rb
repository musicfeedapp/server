require 'spec_helper'

module Aggregator
  module Recognize

    describe Youtube do
      it 'should skip find shazam timeline by url' do
        timeline = Youtube.new("Eminem", "Stan")
        expect(timeline.valid?).to eq(true)
        expect(timeline.name).to eq("Eminem - Stan")
        expect(timeline.youtube_id).to eq("gOMhN-hfMtY")
        expect(timeline.youtube_url).to eq("http://www.youtube.com/v/gOMhN-hfMtY")
        expect(timeline.picture).to eq("https://img.youtube.com/vi/gOMhN-hfMtY/hqdefault.jpg")
      end
    end

  end
end
