module Api
  module Client
    module V1
      class Playlists < Grape::API
        format :json

        include RequestAuth

        resources :playlists do
          helpers do
            def ext_id
              params.fetch(:ext_id) { current_user.ext_id }
            end
          end
          params do
            optional :ext_id, type: String, desc: 'In case of passing ext_id we are getting playlists by external id because of uniq value'
          end
          get '/', rabl: 'v1/playlists/index' do
            scoped = Playlist.order("playlists.updated_at DESC")

            user = current_user

            if ext_id.present?
              user = User.where(ext_id: ext_id).first

              scoped = scoped
                .joins(:user)
                .where("users.ext_id = ?", ext_id)
            end

            if user != current_user
              scoped = scoped.where(is_private: false)
            end

            @playlists = [
              ::Playlists::Default.new(user),
              ::Playlists::Likes.new(user),
            ].map do |playlist|
              playlist.current_user = current_user
              playlist.params = params
              playlist
            end

            @playlists.concat(scoped.to_a)
          end

          SuccessResponse = {}

          params do
            requires :id, type: Integer
          end
          route_param :id do
            delete '/' do
              playlist = ::Playlists::Finder.find_by_id(params[:id], scoped: -> { current_user.playlists } ) do |klass|
                # Otherwise we will use builder as fallback for custom
                # playlists: Default, Likes.
                klass.new(current_user)
              end
              playlist.current_user = current_user
              playlist.params = params
              playlist.destroy

              SuccessResponse
            end
          end

          params do
            optional :title, type: String
            optional :is_private, type: Boolean
          end
          post '/', rabl: 'v1/playlists/playlist' do
            @playlist = current_user.playlists.create!(
              title: params[:title],
              is_private: params[:is_private] || false
            )
          end

          params do
            requires :id, type: String
            optional :ext_id, type: String
            optional :last_timeline_id, type: Integer, desc: 'We are using this last timeline id for unfinite pagination'
          end
          route_param :id do
            get '/', rabl: 'v1/playlists/show' do
              user = current_user

              if ext_id.present?
                user = User.where(ext_id: ext_id).first
              end

              # Example:
              # curl -fsSL -X GET http://localhost:3000/api/client/playlists/default\?authentication_token\=alex.korsak@gmail.com\&email\=alex.korsak@gmail.com\&ext_id\=5R9Xk4x8Uw9qnmunSWeM | jq .
              #
              accessible_playlist_scope = -> {
                user != current_user ? Playlist.where(is_private: false) : Playlist
              }

              @playlist = ::Playlists::Finder.find_by_id(params[:id], scoped: accessible_playlist_scope) do |klass|
                # Otherwise we will use builder as fallback for custom
                # playlists: Default, Likes.
                klass.new(user)
              end

              throw :error, status: 404, message: ErrorSerializer.serialize(not_found_playlist: "Not found playlist by id: #{params[:id]}") if @playlist.nil?

              @playlist.params = params
              @playlist.current_user = current_user

              @timelines, @activities, @publishers = @playlist.timelines
            end
          end

          params do
            requires :id, type: Integer
            optional :title, type: String
            optional :is_private, type: Boolean
          end
          route_param :id do
            put '/', rabl: 'v1/playlists/playlist' do
              @playlist = ::Playlists::Finder.find_by_id(params[:id], scoped: -> { current_user.playlists } ) do |klass|
                # Otherwise we will use builder as fallback for custom
                # playlists: Default, Likes.
                klass.new(current_user)
              end

              throw :error, status: 404, message: ErrorSerializer.serialize(not_found_playlist: "Not found playlist by id: #{params[:id]}") if @playlist.nil?

              @playlist.current_user = current_user
              @playlist.params = params

              attributes = {}
              attributes.merge!(title: params[:title]) if params.has_key?(:title)
              attributes.merge!(is_private: params[:is_private]) if params.has_key?(:is_private)

              if attributes.present?
                @playlist.update_attributes!(attributes)

                if attributes.has_key?(:is_private)
                  current_user.sql_increment!(@playlist.playlists_timelines_count)
                end
              end
            end
          end

          params do
            requires :id, type: String
            optional :timelines_ids, type: Array[String]
          end
          route_param :id do
            post '/add' do
              @playlist = ::Playlists::Finder.find_by_id(params[:id], scoped: -> { current_user.playlists } ) do |klass|
                # Otherwise we will use builder as fallback for custom
                # playlists: Default, Likes.
                klass.new(current_user)
              end
              @playlist.current_user = current_user
              @playlist.params = params

              @playlist.add_timeline(params[:timelines_ids])

              # we should create comments for each passed timeline
              @playlist.timelines_ids.each do |timeline_id|
                comment = Comment.find_or_initialize_by(
                  commentable_type: Timeline.name,
                  commentable_id: timeline_id,
                  user_id: current_user.id,
                  eventable_id: @playlist.id,
                  eventable_type: @playlist.eventable_type,
                )
                comment.save! if comment.new_record?

                PushNotifications::Worker.perform_async(:add_timeline_to_playlist, [current_user.id, @playlist.id, timeline_id])
              end

              SuccessResponse
            end
          end

          params do
            requires :id, type: String
            optional :timelines_ids, type: Array[Integer]
          end
          route_param :id do
            delete '/remove' do
              @playlist = ::Playlists::Finder.find_by_id(params[:id], scoped: -> { current_user.playlists } ) do |klass|
                # Otherwise we will use builder as fallback for custom
                # playlists: Default, Likes.
                klass.new(current_user)
              end
              @playlist.current_user = current_user
              @playlist.params = params
              @playlist.remove_timeline(params[:timelines_ids])

              SuccessResponse
            end
          end
        end
      end # class Playlists
    end # V1
  end # Client
end # Api
