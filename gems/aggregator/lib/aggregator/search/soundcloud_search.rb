require 'soundcloud'

module Aggregator
 module Search

   module SoundcloudSearch
     Attributes = Struct.new(:attributes) do
       def name
         attributes.title
       end

       def link
         return if attributes.nil?
         attributes.permalink_url
       end

       def picture
         return if attributes.artwork_url.nil? && !attributes.user.nil? && attributes.user.avatar_url.nil?

         if !attributes.artwork_url.nil?
           attributes.artwork_url.gsub(/(.*)(large)(.*)/, '\1t500x500\3')
         elsif !attributes["tracks"].nil? && !attributes.tracks.first.artwork_url.nil?
           attributes.tracks.first.artwork_url.gsub(/(.*)(large)(.*)/, '\1t500x500\3')
         elsif !attributes.user.nil?
           attributes.user.
             avatar_url.gsub(/(.*)(large)(.*)/, '\1t500x500\3')
         end
       end

       def artist
         return if attributes.user.nil?
         attributes.user['username']
       end

       def valid?
         !attributes.title.nil?
       end
     end

     def track
       @attributes ||= Attributes.new(
         begin
           response = client.get('/resolve', url: soundcloud_id)

           if response.is_a?(Soundcloud::ArrayResponseWrapper)
             response.first
           else
             response
           end
         rescue ::Soundcloud::ResponseError
           Aggregator::Nullable::Connection.new
         end
       )
     end

     def client
       @client ||= Soundcloud.new(:client_id => Settings.soundcloud.id)
     end
   end

 end
end
