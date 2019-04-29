module Api
  module Client
    module V2
      class Base < Grape::API
        version 'v2', using: :path, cascade: true
        use Rack::Config do |env|
          env['api.tilt.root'] = Rails.root.join('api', 'views', 'client')
        end

        format :json
        formatter :json, Grape::Formatter::Rabl

        mount Api::Client::V2::Profile
        mount Api::Client::V2::Search
        mount Api::Client::V2::Suggestions
        mount Api::Client::V2::Comments
        mount Api::Client::V2::Proposals
      end
    end
  end
end
