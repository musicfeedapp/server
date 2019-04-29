module Api
  module Client
    module V5
      class Base < Grape::API
        version 'v5', using: :path, cascade: true
        use Rack::Config do |env|
          env['api.tilt.root'] = Rails.root.join('api', 'views', 'client')
        end

        format :json
        formatter :json, Grape::Formatter::Rabl

        mount Api::Client::V5::Genres
        mount Api::Client::V5::ContactList
        mount Api::Client::V5::PhoneArtists
        mount Api::Client::V5::Publisher
        mount Api::Client::V5::Suggestions
        mount Api::Client::V5::Users
      end
    end
  end

end
