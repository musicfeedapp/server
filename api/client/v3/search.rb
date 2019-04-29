require 'timeout'

module Api
  module Client
    module V3
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
      end

      TopsSearch = ->(artists, users, timelines, keywords, type) do
        return [], [], [] if type != 'all' && type != 'top'

        artists = artists.sort_by { |a| a.isv }.find { |a| a.username == keywords || a.name == keywords || a.email == keywords }
        artists = Array(artists)

        users = users.find { |a| a.username == keywords || a.name == keywords || a.email == keywords }
        users = Array(users)

        timelines = timelines.find { |a| a.name == keywords || a.link == keywords || a.source_link == keywords || a.youtube_id == keywords || a.itunes_link == keywords }
        timelines = Array(timelines)

        return artists, users, timelines
      end

      TimelinesSearch = ->(user, keywords, type) do
        return [] if type != 'all' && type != 'timelines'

        timelines = Timeline
          .search(keywords)
          .per(25)
          .records
          .joins("INNER JOIN timeline_publishers ON timeline_publishers.timeline_id = timelines.id")
          .joins("INNER JOIN users ON users.facebook_id = timeline_publishers.user_identifier")
          .select <<-SQL
            DISTINCT ON (timelines.id)

            timelines.*,
            EXISTS(
                SELECT 1
                FROM user_likes
                WHERE user_likes.user_id=#{user.id} AND user_likes.timeline_id=timelines.id
            ) AS is_liked
          SQL
          .squish

        timelines = timelines.to_a

        timeline_ids = timelines.map(&:id).join(',')

        timelines_collection = TimelinesCollection.new(user)
        publishers = timelines_collection.publishers_for(timeline_ids)
        activities = timelines_collection.restricted_activities_for(timeline_ids)

        return timelines, activities, publishers
      end

      YoutubeTimelinesSearch = ->(user, keywords, type) do
        return [] if type != 'all' && type != 'timelines'
        Timeline
          .search(keywords)
          .per(100)
          .records
          .joins("INNER JOIN timeline_publishers ON timeline_publishers.timeline_id = timelines.id")
          .joins("INNER JOIN users ON users.facebook_id = timeline_publishers.user_identifier")
          .select(<<-SQL
            DISTINCT ON (timelines.id)

            timelines.*,
            users.name AS author_name,
            users.ext_id AS author_ext_id,
            users.user_type AS user_type
          SQL
          .squish)
          .where(feed_type: 'youtube')
      end

      PlaylistsSearch = ->(user, keywords, type) do
        return [] if type != 'all' && type != 'playlists'
        Playlist.search(keywords, user_id: user.id).per(25).records
      end

      YoutubesSearch = ->(user, keywords, type) do
        return [] if type != 'all' && type != 'youtube'

        begin
            videos = []

            Yourub.logger = Rails.logger

            client = Yourub::Client.new(Settings.youtube.to_h)
            client.search(query: keywords, categories: 'music', order: 'viewCount', max_results: 10) do |response|
              unless response.blank?
                id = response['id']
                link = Aggregator::Providers::Youtube::Link.link(id)
                title = response['snippet']['title']
                author, _ = title.split('-').map(&:strip)[0]

                timeline_id = SecureRandom.uuid

                attributes = {
                  id: timeline_id,
                  generated_id: timeline_id,
                  link: link,
                  youtube_link: link,
                  picture: "https://img.youtube.com/vi/#{id}/hqdefault.jpg",
                  name: title,
                  feed_type: 'youtube',
                  author: author,
                  user_identifier: user.facebook_id,
                  artist: author,
                  source_link: link,
                  comments_count: 0,
                  published_at: DateTime.now,
                  likes_count: 0,
                }

                Cache.set(timeline_id, attributes, expires_in: 30.minutes)

                videos << Timeline.new(attributes)
              end

            return videos
          end
        rescue => boom
          return []
        end
      end

      class Search < Grape::API
        version 'v3', using: :path

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
          get '/', rabl: 'v3/search/index' do
            @users     = FriendsSearch.call(current_user, keywords, search_type)
            @artists   = ArtistsSearch.call(current_user, keywords, search_type)
            @artists   = @artists.to_a.sort_by { |a| a.isv }

            @timelines, @activities, @publishers = TimelinesSearch.call(current_user, keywords, search_type)
            @playlists = PlaylistsSearch.call(current_user, keywords, search_type)
            @top_artists, @top_users, @top_timelines = TopsSearch.call(@artists, @users, @timelines, keywords, search_type)

            @youtubes  = [] # YoutubesSearch.call(current_user, keywords, search_type)
          end

          params do
            optional :keywords, type: String
            optional :search_type, type: String, default: 'all', desc: 'values: all, users, artists, timelines, playlists'
          end
          get '/top', rabl: 'v3/search/top' do
            @top_artists, @top_users, @top_timelines = TopsSearch.call(@artists, @users, @timelines, keywords, search_type)
          end

          params do
            optional :keywords, type: String
            optional :search_type, type: String, default: 'all', desc: 'values: all, users, artists, timelines, playlists'
          end
          get '/youtube', rabl: 'v3/search/index' do
            @users     = []
            @artists   = []
            @playlists = []
            @timelines = YoutubeTimelinesSearch.call(current_user, keywords, search_type)
            @youtubes  = YoutubesSearch.call(current_user, keywords, search_type)
          end
        end
      end

    end
  end
end
