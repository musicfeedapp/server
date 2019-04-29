class UsernamesWorker
  include Sidekiq::Worker

  sidekiq_options retry: false

  Worker = Struct.new(:user_id, :name) do
    def run
      attributes = client.get_object('me', {})
      user.username = attributes['username'].blank? ? Usernameable.get(name) : attributes['username']
      user.save!
    rescue => boom
      Notification.notify(boom, user_id: user_id, name: name)
      raise boom
    end

    def user
      @user ||= User.find(user_id)
    end

    def valid?
      !user.authentications.facebook.expired?
    end

    def client
      @client ||= user.authentications.facebook.client
    end
  end

  def perform(user_id)
    worker = Worker.new(user_id)

    if worker.valid?
      worker.run
    end
  end
end
