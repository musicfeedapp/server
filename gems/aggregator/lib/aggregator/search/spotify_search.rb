require 'faraday'
require 'rspotify'

module Aggregator
 module Search

   module SpotifySearch
     Attributes = Struct.new(:attributes) do
       def name
         attributes['name']
       end

       def artist
         attributes['artists'][0]['name'] rescue nil
       end

       def album
         attributes['album']['name'] rescue nil
       end

       def picture
         attributes['album']['images'][0]['url'] rescue nil
       end

       def uri
         "spotify:track:#{spotify_id}"
       end

       def link
         "http://open.spotify.com/track/#{spotify_id}"
       end

       def spotify_id
         attributes['spotify_id']
       end

       def valid?
         !name.nil?
       end
     end

     SPOTIFY_API = "https://api.spotify.com/v1/tracks/%s"
     def track
       @attributes ||= begin
                         response = Faraday.get(SPOTIFY_API % spotify_id)

                         if response.status != 200
                           Attributes.new({})
                         else
                           Attributes.new(JSON.parse(response.body).merge('spotify_id' => spotify_id))
                         end
                       end
     end
   end

 end
end
