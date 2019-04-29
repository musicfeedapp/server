module Api
  module Client
    module V1
      class Timelines < Grape::API
        format :json

        include RequestAuth

        resources :timelines do
          params do
            optional :feed_type          , type: String
            optional :timestamp          , type: DateTime
            optional :last_timeline_id   , type: Integer
            optional :exclude_feed_types , type: Array    , desc: "Posibility to exclude the specific types of the timelines from the list"
            optional :facebook_user_id   , type: String   , desc: 'Facebook user id for filtering the timelines objects(uid of the user in the facebook)'
            optional :my                 , type: Boolean  , desc: 'Show only my music', default: false
            optional :favourites         , type: Boolean  , desc: 'Showing only favourites', default: false
          end
          get '/', rabl: 'v1/timelines/index' do
            Cache.set("lfv:#{current_user.facebook_id}", DateTime.now)

            timelines_collection = TimelinesCollection.new(current_user, params)

            # if (timelines_cache = Cache.get("tc:#{current_user.facebook_id}:#{params[:last_timeline_id].to_s}")).present?
            #   @timelines, @activities, @publishers = nil, nil, nil
            #
            #   StatsD.measure('api.timelines.cache_list') do
            #     timelines_cache = JSON.parse(timelines_cache).join(',')
            #
            #     @timelines = Timeline.find_by_sql(%Q{
            #       SELECT timelines.*,
            #         EXISTS(SELECT 1 FROM user_likes ul WHERE ul.timeline_id=timelines.id AND ul.user_id=#{current_user.id}) AS is_liked
            #       FROM   timelines
            #       WHERE  timelines.id IN(#{timelines_cache})
            #       ORDER  BY idx(array[#{timelines_cache}], timelines.id)
            #     }.squish)
            #
            #     timeline_ids = @timelines.map(&:id).join(',')
            #     @publishers = timelines_collection.publishers_feed_for(timeline_ids)
            #     @activities = timelines_collection.activities_for(timeline_ids)
            #   end
            # else
            @timelines, @activities, @publishers = nil, nil, nil

            StatsD.measure('api.timelines.list') do
              @timelines, @activities, @publishers = timelines_collection.find_by_shared
            end
            # end
          end

          SuccessResponse = {}

          params do
            optional :page_number, type: Integer, default: 1
          end
          get '/trending_tracks', rabl: 'v1/timelines/index' do
            @timelines, @activities, @publishers = nil, nil, nil

            StatsD.measure('api.timelines.trending_tracks') do
              @timelines, @activities, @publishers = current_user.trending_tracks(params[:page_number])
            end
          end

          params do
            requires :id
          end
          route_param :id do
            delete '/' do
              timeline = Timeline.find(params[:id])

              StatsD.measure('api.timelines.restrict') do
                @restrictions = TimelineRestrictions.new(current_user)
                @restrictions.restrict!(timeline)
              end

              { unfollow: @restrictions.unfollowable?(timeline) }
            end
          end

          params do
            requires :id
          end
          route_param :id do
            put '/like' do
              StatsD.measure('api.timelines.like') do
                current_user.like!(params[:id])
              end

              PushNotifications::Worker.perform_async(:like, [current_user.id, params[:id]])
              SuccessResponse
            end
          end

          params do
            requires :id
          end
          route_param :id do
            put '/unlike' do
              StatsD.measure('api.timelines.unlike') do
                current_user.unlike!(params[:id])
              end

              SuccessResponse
            end
          end

          get '/removed', rabl: 'v1/timelines/index' do
            @timelines, @publishers = nil

            @timelines = Timeline.only_restricted(current_user)

            if current_user.restricted_timelines.size > 0
              @timelines = @timelines.order("idx(array[#{current_user.restricted_timelines.join(',')}], timelines.id) DESC")
            end

            timelines_collection = TimelinesCollection.new(current_user, params)

            # Tyrone Tranmer: email=tyronetranmer@gmail.com
            StatsD.measure('api.timelines.removed') do
              @timelines = @timelines.to_a

              timeline_ids = @timelines.map(&:id).join(',')
              @publishers = timelines_collection.publishers_for(timeline_ids)
              @activities = timelines_collection.restricted_activities_for(timeline_ids)
            end
          end

          params do
            requires :timeline_id, type: String, desc: 'Timeline id that should be restored'
          end
          post '/removed/:timeline_id/restore' do
            StatsD.measure('api.timelines.restore') do
              timeline = Timeline.only_restricted(current_user).find(params[:timeline_id])

              restrictions = TimelineRestrictions.new(current_user)
              restrictions.restore!(timeline)
            end

            SuccessResponse
          end

          params do
            requires :id
          end
          route_param :id do
            get '/', rabl: 'v1/timelines/show' do
              @timeline = nil

              StatsD.measure('api.timelines.show') do
                @timeline = Timeline.find_by_id(params[:id])
              end

              timelines_collection = TimelinesCollection.new(current_user, params)
              timeline_ids = @timeline.id.to_s
              @publishers = timelines_collection.publishers_for(timeline_ids)
              @activities = timelines_collection.restricted_activities_for(timeline_ids)

              @timeline
            end
          end
        end

      end
    end
  end
end
