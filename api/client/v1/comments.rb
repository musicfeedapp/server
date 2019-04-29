class Api::Client::V1::Comments < Grape::API
  format :json

  include RequestAuth

  namespace :timelines do
    params do
      requires :timeline_id, type: String, desc: 'Database id of the timeline'
    end

    helpers do
      def timeline
        @timeline ||= Timeline.find(params[:timeline_id])
      end
    end

    route_param :timeline_id do
      resources :comments do

        get '/', rabl: 'v1/comments/index' do
          @comments = timeline.comments.includes(:user)
        end

        params do
          requires :comment, type: String, desc: 'Awesome text message to show it in the comments list'
        end
        post '/', rabl: 'v1/comments/show' do
          @comment = timeline.comments.create!(
            comment: params[:comment],
            user: current_user,
          )
          PushNotifications::Worker.perform_async(:add_comment, [current_user.id, @comment.id, timeline.id])
        end

        route_param :id do
          delete '/' do
            @comment = timeline.comments.find(params[:id])
            @comment.destroy
          end
        end

      end
    end
  end # timelines

end
