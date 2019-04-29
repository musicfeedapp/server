require 'spec_helper'

require 'sidekiq/testing'

module Api
  module Client
    module V2

      describe Search do
        before do
          client = Playlist.__elasticsearch__.client

          if client.indices.exists(index: 'playlists-test')
            client.indices.delete(index: 'playlists-test')
          end

          if client.indices.exists(index: 'timelines-test')
            client.indices.delete(index: 'timelines-test')
          end

          if client.indices.exists(index: 'users-test')
            client.indices.delete(index: 'users-test')
          end
        end

        let(:user) { create(:user) }

        it 'should search friends and friend of friends' do
          user1 = nil
          user2 = nil
          user3 = nil
          user4 = nil

          Sidekiq::Testing.inline! do
            user1 = create(:user, name: 'Alex Korsak', facebook_id: 'facebook-id1')
            user2 = create(:user, name: 'Bob Marley', facebook_id: 'facebook-id2')
            user3 = create(:user, name: 'Emenime Bob', facebook_id: 'facebook-id3')
            user4 = create(:user, name: 'James Eminem', facebook_id: 'facebook-id4')
          end

          sleep 1

          user1.friend!(user2)
          user3.friend!(user4)

          users = user1.friend_search('Bob').records.to_a

          expect(users.size).to eq(2)
          expect(users).to include(user2)
          expect(users).to include(user3)

          users = user4.friend_search('bob').records.to_a
          expect(users.size).to eq(2)
          expect(users).to include(user2)
          expect(users).to include(user3)

          users = user4.friend_search('ddab').records.to_a
          expect(users.size).to eq(0)

          # user5 = create(:user, name: 'TOMO*TOMOTEAM', facebook_id: 'facebook-id4', user_type: 'artist')
          # user6 = create(:user, name: 'Boyd Kosiyabong', facebook_id: 'facebook-id4', user_type: 'artist')

          # sleep 1

          # users = user3.artist_search('todd').records.to_a
          # expect(users.size).to eq(0)

          # users = user3.artist_search('tomo').records.to_a
          # expect(users.size).to eq(1)

          # users = user3.artist_search('kosyab').records.to_a
          # expect(users.size).to eq(1)

          # user7 = create(:user, name: 'DJ MARI Ferrari', facebook_id: 'facebook-id4', user_type: 'artist')
          # user8 = create(:user, name: 'DJ NONSTOP', facebook_id: 'facebook-id4', user_type: 'artist')

          # sleep 1

          # users = user3.artist_search('dj fresh').records.to_a
          # expect(users.size).to eq(0)

          # users = user3.artist_search('non stop').records.to_a
          # expect(users.size).to eq(1)

          # users = user3.artist_search('none stop').records.to_a
          # expect(users.size).to eq(1)
        end

        it 'should search timelines' do
          timeline1 = nil
          timeline2 = nil
          timeline3 = nil

          Sidekiq::Testing.inline! do
            timeline1 = create(:timeline, user: user, name: 'Bob Marley')
            timeline2 = create(:timeline, user: user, name: 'Mike Pipe')
            timeline3 = create(:timeline, user: user, name: 'Static X')
          end

          sleep 1

          timelines = Timeline.search('Bob').records.to_a
          expect(timelines.size).to eq(1)
          expect(timelines).to include(timeline1)

          timelines = Timeline.search('Static').records.to_a
          expect(timelines.size).to eq(1)
          expect(timelines).to include(timeline3)
        end

        it 'should be possible to search playlists and skip private playlists' do
          user1 = nil
          user2 = nil
          user3 = nil

          playlist1 = nil
          playlist2 = nil
          playlist3 = nil

          Sidekiq::Testing.inline! do
            user1 = create(:user)
            user2 = create(:user)
            user3 = create(:user)

            playlist1 = create(:playlist, user: user1, title: 'aaaa dddd')
            playlist2 = create(:playlist, user: user2, title: 'bbbb dddd')
            playlist3 = create(:playlist, user: user3, title: 'cccc dddd')
          end

          sleep 1

          playlists = Playlist.search('aaaa', user_id: user1.id).records.to_a
          expect(playlists.size).to eq(1)
          expect(playlists).to include(playlist1)

          playlists = Playlist.search('dddd', user_id: user1.id).records.to_a
          expect(playlists.size).to eq(3)
          expect(playlists).to include(playlist1)
          expect(playlists).to include(playlist2)
          expect(playlists).to include(playlist3)

          Sidekiq::Testing.inline! do
            playlist1.update_attributes!(is_private: true)
          end
          sleep 1

          playlists = Playlist.search('dddd', user_id: user1.id).records.to_a
          expect(playlists.size).to eq(3)
          expect(playlists).to include(playlist1)
          expect(playlists).to include(playlist2)
          expect(playlists).to include(playlist3)

          Sidekiq::Testing.inline! do
            playlist2.update_attributes!(is_private: true)
          end
          sleep 1

          playlists = Playlist.search('dddd', user_id: user1.id).records.to_a
          expect(playlists.size).to eq(2)
          expect(playlists).to include(playlist1)
          expect(playlists).to include(playlist3)
        end
      end

    end

  end
end
