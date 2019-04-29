require 'benchmark'

module Api
  module Client
    module V5

      class Suggestions < Grape::API
        version 'v5', using: :path

        format :json

        include RequestAuth

        helpers do
          def page_number
            params[:page_number] || 1
          end

          def filter_type
            params[:filter_type]
          end
        end

        CATEGORIES = User::SuggestionFilter::Filter.keys
        LIKES = User::LIKE_TYPES

        resources :suggestions do
          get '/categories' do
            CATEGORIES.map{ |key| { key: key.to_s, title: key.to_s.titleize } }
          end

          params do
            optional :filter_type, type: String, desc: "filter suggestions based on category type, can be #{LIKES.join(', ')} and #{CATEGORIES.join(', ')}, you can join by ','"
            optional :page_number, type: Integer, default: 1
          end
          get '/', rabl: 'v5/suggestions/index' do
            service = SuggestionsService.new(current_user)

            @artists = nil
            @timelines, @activities, @publishers = nil, nil, nil

            @trending_artists = nil
            @trending_artists_timelines, @trending_artists_activities, @trending_artists_publishers = nil, nil, nil

            @trending_tracks_timelines, @trending_tracks_activities, @trending_tracks_publishers = nil, nil, nil

            @common_followers = nil

            Benchmark.bm do |benchmark|
              benchmark.report do
                @artists = service.artists_by_filter(filter_type, page_number)
              end

              benchmark.report do
                @timelines, @activities, @publishers = service.timelines
                @artists = @artists.select { |artist| @timelines[artist.id].size > 0 }
              end

              benchmark.report do
                @trending_artists = service.trending_artists
              end

              benchmark.report do
                @trending_artists_timelines, @trending_artists_activities, @trending_artists_publishers = service.trending_artists_timelines
                @trending_artists = @trending_artists.select { |artist| @timelines[artist.id].size > 0 }
              end

              benchmark.report do
                @trending_tracks_timelines, @trending_tracks_activities, @trending_tracks_publishers = service.trending_tracks
              end

              benchmark.report do
                @common_followers = service.common_followers(@artists)
              end
            end
          end

          get '/feed_count' do
            feed_counter = UpdateFeedAppIconCountWorker::UserFeedCounter.new(current_user)
            feed_count = feed_counter.perform

            PushNotifications::Worker.perform_async(:feed_count, [current_user.id, feed_count])
          end
        end

      end
    end
  end
end
