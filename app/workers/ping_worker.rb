class PingWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :heavy, :retry => false, :unique => :while_executing

  Pinger = Struct.new(:user) do
    include Facebook::Fb::Connection

    def perform
      user.authentications.facebook.auth_token
    end
  end

  def perform
    User.joins(:authentications).each do |user|
      next if user.authentications.empty?

      begin
        pinger = Pinger.new(user)
        pinger.perform
      rescue => boom
        begin
          user.authentications.facebook.regenerate_auth_token
        rescue => boom
          # Lets mark authentications expired few days ago.
          authentication = user.authentications.facebook.authentication

          if authentication
            authentication.update_attributes!(expires_at: 1.day.ago)
          end
        end # rescue

      end # rescue
    end
  end
end
