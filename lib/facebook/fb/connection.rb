module Facebook
  module Fb

    module Connection
      #
      # @note Base class should implement methods user and who
      #
      def facebook
        @facebook ||= Koala::Facebook::API.new(auth_token)
      end

      def auth_token
        raise 'should be implemented'
      end

      def friends
        @friends ||= facebook.get_connections('me', 'friends', {}, { api_version: 'v2.3' })
      end

      def read_all_as_collection(connections)
        collection = connections.to_a

        begin
          while connections = connections.next_page
            collection.concat(connections.to_a)
            break if connections.to_a.size == 0
          end
        rescue => boom
          Notification.notify(boom, from: "Facebook::Fb::Connection")
          # @note for some reasons facebook api is raising the issues sometimes
          # on paging some of the resouces. we should skip further paginations
          # and continue to review the data.
        end

        collection
      end
    end

  end
end
