require 'sinatra'
require 'net/http'
require 'net/https'
require 'base64'
require 'json'
require 'encrypted_strings'

module Api

  module Client
    CLIENT_ID                 = Rails.configuration.spotify.id
    CLIENT_SECRET             = Rails.configuration.spotify.secret
    CLIENT_CALLBACK_URL       = Rails.configuration.spotify.callback
    ENCRYPTION_SECRET         = "HTsGjmpaPiAeCwxntkSSsglxqkJBR6Fu"
    AUTH_HEADER               = "Basic " + Base64.strict_encode64(CLIENT_ID + ":" + CLIENT_SECRET)
    SPOTIFY_ACCOUNTS_ENDPOINT = URI.parse("https://accounts.spotify.com")

    class Spotify < Grape::API
      format :txt

      resource :spotify do
        post '/swap' do
          auth_code = params[:code]

          http = Net::HTTP.new(SPOTIFY_ACCOUNTS_ENDPOINT.host, SPOTIFY_ACCOUNTS_ENDPOINT.port)
          http.use_ssl = true

          request = Net::HTTP::Post.new("/api/token")
          request.add_field("Authorization", AUTH_HEADER)

          request.form_data = {
            "grant_type"        => "authorization_code",
            "redirect_uri"      => CLIENT_CALLBACK_URL,
            "code"              => auth_code
          }

          response = http.request(request)

          # encrypt the refresh token before forwarding to the client
          if response.code.to_i == 200
            token_data                  = JSON.parse(response.body)
            refresh_token               = token_data["refresh_token"]
            encrypted_token             = refresh_token.encrypt(:symmetric, :password => ENCRYPTION_SECRET)
            token_data["refresh_token"] = encrypted_token
            response.body               = JSON.dump(token_data)
          end

          status response.code.to_i

          response.body
        end # /swap


        post '/refresh' do
          http = Net::HTTP.new(SPOTIFY_ACCOUNTS_ENDPOINT.host, SPOTIFY_ACCOUNTS_ENDPOINT.port)
          http.use_ssl = true

          request = Net::HTTP::Post.new("/api/token")
          request.add_field("Authorization", AUTH_HEADER)

          encrypted_token = params[:refresh_token]
          refresh_token = encrypted_token.decrypt(:symmetric, :password => ENCRYPTION_SECRET)

          request.form_data = {
            "grant_type"    => "refresh_token",
            "refresh_token" => refresh_token
          }
          response = http.request(request)

          status response.code.to_i
          response.body
        end # /refresh
      end # spotify

    end # Spotify

  end # Client

end

