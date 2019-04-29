module Socialable
  module Facebook

    Provider = Struct.new(:authentication) do
      # @note easy access to facebook api using the latest auth token
      def client
        @client ||= Koala::Facebook::API.new(auth_token)
      end

      def uid
        authentication.uid
      end

      def expired_for_today?
        return true if authentication.nil?
        authentication.expires_at < DateTime.now.utc
      end

      # In case of expiration it will retyrn true
      #
      # @return [Boolean]
      def expired?
        return true if authentication.nil?

        authentication.expires_at < 2.days.from_now
      end

      # Return auth token for accessing to the facebook api endpoints.
      # If the auth token is expired it will regenerate auth token with 60
      # days expiration time.
      #
      # @return [String]
      def auth_token
        return regenerate_auth_token if expired?

        authentication.auth_token
      end

      # Using Koala gem it will regenerate auth token using the old
      # auth token and assign to the stored user authentication method.
      def regenerate_auth_token
        new_token = oauth.exchange_access_token_info(authentication.auth_token)

        # Save the new token and its expiry over the old one
        authentication.update_attributes!(
          auth_token:       new_token['access_token'],
          last_expires_at:  authentication.expires_at,
          expires_at:       Time.now + new_token['expires_in'].to_i,
        )

        authentication.auth_token
      end

      def oauth
        @oauth ||= Koala::Facebook::OAuth.new(Rails.configuration.facebook.id, Rails.configuration.facebook.secret)
      end
    end

    module ClassMethods

      def find_for_facebook(user, auth)
        user = user || Authentication.find_user_by_auth(auth)

        link = auth.info['urls']['Facebook']

        unless user.present?
          user = create_user_by_auth(auth,
                                     name:           auth.extra['raw_info']['name'],
                                     email:          auth.info["email"],
                                     facebook_link:  link,
                                     facebook_id:    auth.uid.to_s,
                                    )
        end

        if user.present?
          # TODO: for some reasons it doesn't work properly passing v1.0 to
          # koala get request. On passing username that facebook removed from
          # api access it raise error.
          fields_v1 = 'cover,username,is_verified'
          fields_v2 = 'cover,is_verified'

          client = user.authentications.facebook.client
          attributes = client.get_object('me', { fields: fields_v2 })

          username = attributes['username']
          background = attributes.fetch('cover', {})['source']

          begin
            user.update_attributes!(
              is_verified:   attributes['is_verified'],
              background:    background,
              username:      username,
              facebook_link: link,
              facebook_id:   auth.uid.to_s,
            )
          rescue => boom
            Notification.notify(boom, user.attributes)
          end
        end

        user
      end

    end # ClassMethods

  end # Facebook
end
