require 'spec_helper'

module Aggregator
  module Providers
    module Spotify

      describe Link do
        describe '.id' do
          subject { Link }

          let(:id)    { "6aetLFWA1GRIbrTkebRjJW" }
          let(:link)  { "http://open.spotify.com/track/6aetLFWA1GRIbrTkebRjJW" }
          let(:uri)   { "spotify:track:6aetLFWA1GRIbrTkebRjJW" }

          let(:possible_links) do
            [
             link,
             "http://open.spotify.com/album/6aetLFWA1GRIbrTkebRjJW",
             "spotify:track:6aetLFWA1GRIbrTkebRjJW",
             "spotify:album:6aetLFWA1GRIbrTkebRjJW"
            ]
          end

          it 'picks id' do
            expect(subject.id(possible_links[0])).to eq(id)
            expect(subject.id(possible_links[1])).not_to be
            expect(subject.id(possible_links[2])).to eq(id)
            expect(subject.id(possible_links[3])).not_to be
          end

          it 'picks uries' do
            expect(subject.uri(possible_links[0])).to eq(uri)
            expect(subject.uri(possible_links[1])).not_to be
            expect(subject.uri(possible_links[2])).to eq(uri)
            expect(subject.uri(possible_links[3])).not_to be
          end
        end
      end

    end
  end
end
