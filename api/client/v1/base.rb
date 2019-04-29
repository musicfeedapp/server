module Api
  module Client
    module V1
      class Base < Grape::API
        use Rack::Config do |env|
          env['api.tilt.root'] = Rails.root.join('api', 'views', 'client')
        end

        format :json
        formatter :json, Grape::Formatter::Rabl

        mount Api::Client::V1::Users
        mount Api::Client::V1::Timelines
        mount Api::Client::V1::Songs
        mount Api::Client::V1::Proposals
        mount Api::Client::V1::Profile
        mount Api::Client::V1::Intro
        mount Api::Client::V1::Comments
        mount Api::Client::V1::Itunes
        mount Api::Client::V1::Playlists
        mount Api::Client::V1::Search
        mount Api::Client::V1::FacebookClient
      end
    end
  end
end
