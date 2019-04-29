class UserArtistInfoWorker
  include Sidekiq::Worker

  Worker = Struct.new(:user_id, :name) do
    def run
      if artist.present?
        user.follow!(artist)
      else
        # Lets have the record in the database for these users from the itunes
        # collection.
        User.create!(
          name: name,
          user_type: 'artist',
          email: "#{SecureRandom.hex(6)}@example.com",
          enabled: false,
        )
      end
    rescue => boom
      Notification.notify(boom, user_id: user_id, name: name)
      raise boom
    end

    def artist
      @artist ||= User.artist.find_by_name(name)
    end

    def user
      @user ||= User.user.find(user_id)
    end
  end

  def perform(user_id, name)
    worker = Worker.new(user_id, name)
    worker.run
  end
end
