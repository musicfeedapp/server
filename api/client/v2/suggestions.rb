module Api
  module Client
    module V2

      class Suggestions < Grape::API
        version 'v2', using: :path

        format :json

        include RequestAuth

        SuccessResponse = {}

        helpers do
          def facebook_id
            params[:facebook_id].to_s
          end
        end

        resources :suggestions do
          # TODO: dont support v2 suggestions anymore
          get '/', rabl: 'v2/suggestions/index' do
            @artists = []
            @timelines = {}
            @users = []
            @trending_artists = []
            @common_followers = []
          end

          route_param :facebook_id do
            get '/timelines', rabl: 'v2/suggestions/timelines' do
              @artist = User.find_by_facebook_id(facebook_id.to_s)
              @timelines, @activities, @publishers = Timeline.suggestions_for(current_user, facebook_id.to_s)
            end

            post '/follow' do
              @artist = User.find_by_facebook_id(facebook_id.to_s)
              current_user.follow!(@artist)
              SuccessResponse
            end
          end
        end
      end

    end
  end
end

