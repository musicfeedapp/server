class Api::Client::V1::Songs < Grape::API
  format :json

  include RequestAuth

  SuccessResponse = {}

  resources :songs do
    get '/', rabl: 'v1/songs/index' do
      @songs = []
    end

    params do
      requires :timeline_id, type: String, desc: "Timeline Id"
    end
    post '/' do
      current_user.like!(params[:timeline_id])
      PushNotifications::Worker.perform_async(:like, [current_user, params[:timeline_id]])
      SuccessResponse
    end

    params do
      requires :id, type: String, desc: "Song id"
    end
    route_param :id do
      delete '/' do
        current_user.unlike!(params[:id])
        SuccessResponse
      end
    end

  end

end
