class Api::Client::V3::Notifications < Grape::API
  format :json

  include RequestAuth

  helpers do
    def page_no
      params[:page_no] || 1
    end
  end

  resource :notifications do
    params do
      optional :page_no, type: Integer, desc: "optional paramter for pagination by default is 1"
    end
    get '/', rabl: 'v3/notifications/show' do
      notifications_adapter = NotificationAdapter.new(current_user)
      @notifications = notifications_adapter
                       .notitications
                       .includes(:timeline, :sender)
                       .page(page_no)
    end

    params do
      optional :page_no, type: Integer, desc: "optional paramter for pagination by default is 1"
    end
    get '/unreviewed_notifications', rabl: 'v3/notifications/show' do
      notifications_adapter = NotificationAdapter.new(current_user)
      @notifications = notifications_adapter
                       .unreviewed_notifications
                       .includes(:timeline, :sender)
                       .page(page_no)
    end

    get '/unreviewed_notifications_count' do
      notifications_adapter = NotificationAdapter.new(current_user)
      notifications_adapter.unreviewed_notifications_count
    end

    params do
      requires :notifications_ids, type: Array
    end
    post '/read_all', rabl: 'v3/notifications/show' do
      @notifications = UserNotification.where(id: params["notifications_ids"])
      @notifications.update_all(status: UserNotification.statuses[:READ])
    end

    params do
      requires :notifications_ids, type: Array
    end
    post '/seen_all', rabl: 'v3/notifications/show' do
      @notifications = UserNotification.where(id: params["notifications_ids"])
      @notifications.update_all(status: UserNotification.statuses[:SEEN])
    end

    params do
      requires :notification_id, type: Integer
    end
    post '/read', rabl: 'v3/notifications/show' do
      @notifications = UserNotification.find(params["notification_id"])
      @notifications.update(status: "READ")
    end

    params do
      requires :notifications_ids, type: Array
    end
    post '/seen', rabl: 'v3/notifications/show' do
      @notifications = UserNotification.where(id: params["notifications_ids"])
      @notifications.update(status: "SEEN")
    end
  end
end
