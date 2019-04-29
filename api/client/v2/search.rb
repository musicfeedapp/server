module Api
  module Client
    module V2
      FriendsSearch = ->(user, keywords, type) do
        return [] if type != 'all' && type != 'users'
        user
          .friend_search(keywords)
          .per(25)
          .records
          .with_is_followed(user)
      end

      ArtistsSearch = ->(user, keywords, type) do
        return [] if type != 'all' && type != 'artists'
        user
          .artist_search(keywords)
          .per(25)
          .records
          .with_is_followed(user)
          .where("users.timelines_count > 0 OR users.category='Musician/Band'")
      end

      TimelinesSearch = ->(user, keywords, type) do
        return [], [], [] if type != 'all' && type != 'timelines'

        timelines = Timeline
          .search(keywords)
          .per(25)
          .records
          .select <<-SQL
            DISTINCT ON (timelines.id)

            timelines.*,
            EXISTS(
              SELECT 1
              FROM user_likes ul
              WHERE ul.timeline_id=timelines.id AND ul.user_id=#{user.id}
            ) AS is_liked
          SQL

        timeline_ids = timelines.map(&:id).join(',')

        timelines_collection = TimelinesCollection.new(user)
        publishers = timelines_collection.publishers_for(timeline_ids)
        activities = timelines_collection.restricted_activities_for(timeline_ids)

        return timelines, activities, publishers
      end

      PlaylistsSearch = ->(user, keywords, type) do
        return [] if type != 'all' && type != 'playlists'
        Playlist.search(keywords, user_id: user.id).per(25).records
      end

      class Search < Grape::API
        version 'v2', using: :path

        format :json

        include RequestAuth

        helpers do
          def keywords
            params[:keywords]
          end

          def search_type
            params[:search_type]
          end
        end
        resource :search do
          params do
            optional :keywords, type: String
            optional :search_type, type: String, default: 'all', desc: 'values: all, users, artists, timelines, playlists'
          end
          get '/', rabl: 'v2/search/index' do
            @users     = FriendsSearch.call(current_user, keywords, search_type)
            @artists   = ArtistsSearch.call(current_user, keywords, search_type)
            @timelines, @activities, @publishers = TimelinesSearch.call(current_user, keywords, search_type)
            @playlists = PlaylistsSearch.call(current_user, keywords, search_type)
          end
        end
      end

    end
  end
end
