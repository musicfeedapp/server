require 'sidekiq'
require 'sidekiq/web'

module Api
  module Client

    class Server < Grape::API
      include Api::AwesomeLogger
      helpers Api::Client::V1::Auth

      mount Api::Client::V1::Base
      mount Api::Client::V2::Base
      mount Api::Client::V3::Base
      mount Api::Client::V4::Base
      mount Api::Client::V5::Base

      mount Api::Client::Spotify
    end

  end
end
