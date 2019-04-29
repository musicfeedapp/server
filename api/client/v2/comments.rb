module Api
  module Client
    module V2
      SuccessResponse = {}

      class Comments < Grape::API
        version 'v2', using: :path

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

              get '/', rabl: 'v2/comments/index' do
                @comments = timeline.activities.includes(:user).where("comments.user_id!='2309391'").to_a
              end

              params do
                requires :comment, type: String, desc: 'Awesome text message to show it in the comments list'
              end
              post '/', rabl: 'v2/comments/show' do
                @comment = timeline.activities.create!(
                  comment: params[:comment],
                  user: current_user,
                )
                PushNotifications::Worker.perform_async(:add_comment, [current_user.id, @comment.id, timeline.id])
              end

              params do
                requires :comment, type: String, desc: 'Some message'
              end
              route_param :id do
                put '/' do
                  @comment = timeline.activities.find(params[:id])

                  if current_user != @comment.user
                    throw :error, status: 403, message: ErrorSerializer.serialize(unauthorized_access: "You don't have permission to edit this comment.")
                  end

                  @comment.update_attributes(comment: params[:comment])

                  @comment
                end
              end

              route_param :id do
                delete '/' do
                  @comment = timeline.activities.find(params[:id])

                  if current_user != @comment.user
                    throw :error, status: 403, message: ErrorSerializer.serialize(unauthorized_access: "You don't have permission to edit this comment.")
                  end

                  @comment.destroy

                  SuccessResponse
                end
              end

            end
          end
        end # timelines

      end

    end
  end
end
