require 'spec_helper'

module Aggregator
  module Providers
    module Youtube

      describe Link do
        describe '.id' do
          subject { Link }

          let(:id) { "yo9ltfmS5n4" }
          let(:link) { "http://www.youtube.com/v/yo9ltfmS5n4" }

          let(:possible_links) do
            [
             "http://www.youtube.com/v/yo9ltfmS5n4",
             "http://www.youtube.com/watch?v=yo9ltfmS5n4",
             "https://www.youtube.com/watch?v=yo9ltfmS5n4",
             "https://www.youtube.com/watch?v=yo9ltfmS5n4#test=param1",
             "https://www.youtube.com/watch?v=yo9ltfmS5n4&test=param1",
             "https://www.youtube.com/watch?v=yo9ltfmS5n4&index=2",
             "https://www.youtube.com/v/yo9ltfmS5n4&index=2",
             "http://www.youtube.com/attribution_link?a=3GW6p2yj67o&u=%2Fwatch%3Fv%3D#{id}%26feature%3Dshare",
             "http://www.youtube.com/attribution_link?a=bxcJolSOapM&u=%2Fwatch%3Fv%3D#{id}%26feature%3Dshare%26list%3DPLE7tQUdRKcyYOPhZMxw2h84PpO8CIjqsK",
             "http://youtu.be/yo9ltfmS5n4",
             "http://youtu.be/yo9ltfmS5n4&list=PLCuEH5Tl2B8pNiAzALVqHwmQxp8mt-naG"
            ]
          end

          it 'parses youtube id' do
            11.times do |i|
              expect(subject.id(possible_links[i])).to eq(id)
            end
          end

          it 'generates right youtube url' do
            11.times do |i|
              expect(subject.normalize_link(possible_links[i])).to eq(link)
            end
          end
        end
      end

    end
  end
end
