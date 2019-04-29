module Api
  module Client
    module V3
      class Base < Grape::API
        version 'v3', using: :path, cascade: true

        use Rack::Config do |env|
          env['api.tilt.root'] = Rails.root.join('api', 'views', 'client')
        end

        format :json
        formatter :json, Grape::Formatter::Rabl

        mount Api::Client::V3::Search
        mount Api::Client::V3::Profile
        mount Api::Client::V3::Notifications
      end
    end
  end
end
