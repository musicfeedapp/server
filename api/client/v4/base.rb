module Api
  module Client
    module V4
      class Base < Grape::API
        version 'v4', using: :path, cascade: true
        use Rack::Config do |env|
          env['api.tilt.root'] = Rails.root.join('api', 'views', 'client')
        end

        format :json
        formatter :json, Grape::Formatter::Rabl

        mount Api::Client::V4::Unsigned
        mount Api::Client::V4::Itunes
      end
    end
  end

end
