require 'facebook/fb/connection'

module Apiable

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def find_or_create_by_facebook_auth_token(auth_token, options={})
      options.stringify_keys!

      user_facebook = UserFacebookApi.new(auth_token, options)
      user_facebook.find_or_create_by_facebook_auth_token

      user = user_facebook.user

      [user, { new_user: user_facebook.new_user? }]
    end

    UserFacebookApi = Struct.new(:auth_token, :options) do
      # Because of using auth_token as entry param of structure it will
      # automatically override method auth_token of Fb::Connection module and
      # allow us to use facebook client
      include Facebook::Fb::Connection

      def new_user?
        @new_user
      end

      FIELDS_V1 = 'id,birthday,email,first_name,last_name,middle_name,gender,link,timezone,website,cover,username,is_verified'

      FIELDS_V2 = 'id,birthday,email,first_name,last_name,middle_name,gender,link,timezone,website,cover,is_verified'

      def attributes
        @attributes ||= facebook.get_object("me", { fields: FIELDS_V2 })
      end

      # When we have email user and we give the facebook id of user that we already have in DB
      # then it return 2 records and it is returning the user matched on facebook id instead of
      # the real user needed

      def user
        condition = if options['email']
                      "email = '#{options['email']}'"
                    else
                      "facebook_id = '#{attributes['id'].to_s}' OR device_id = '#{options['device_id']}'"
                    end

        @user ||= User.where(condition).first_or_initialize
      end

      def find_or_create_by_facebook_auth_token
        if user.persisted?
          update!
        else
          create!
        end
      end

      def background
        attributes.fetch('cover', {})['source']
      end

      def sync_user_attributes!
        # We should change primary email address but it would be better to store the old email.
        if user.email != attributes['email']
          # lets store under system keys possible user emails for further review.
          # - in case of having the troubles with sign in we should always allow to make login
          $redis.sadd("sy:#{user.id}:es", user.email)

          user.email = attributes['email']
        end

        # For signed in user we should use is_verified for now.
        user.is_verified         = attributes['is_verified']
        user.first_name          = attributes['first_name']
        user.last_name           = attributes['last_name']
        user.middle_name         = attributes['middle_name']
        user.facebook_link       = attributes['link']
        user.facebook_id         = attributes['id'].to_s
        user.background          = background
        user.username            = attributes['username'].blank? ? Usernameable.get(attributes['name']) : attributes['username']
        user.device_id           = options['device_id']
        user.last_feed_viewed_at = DateTime.now

        # should contains email, facebook, or 'email,facebook'
        user.login_method = [*user.login_method.to_s.split(','), "facebook"].uniq.select(&:present?).join(',')

        if user.email.blank?
          user.email = "#{user.facebook_id}@facebook.com"
        end

        user.remove_avatar = options['remove_avatar']

        user.save!
      end

      def create!
        @new_user = true

        # destroy all the anonymous users created on coming device_id
        if options['device_id'].present?
          User.user.where(device_id: options['device_id'], facebook_id: nil).destroy_all
        end

        user.password = Devise.friendly_token[0,20]
        sync_user_attributes!
        sync_facebook_authentication!
      end

      def update!
        @new_user = false

        sync_user_attributes!
        sync_facebook_authentication!
      end

      def sync_facebook_authentication!
        authentication = user.authentications.find_or_initialize_by(
          email:     user.email,
          provider:  'facebook',
          uid:       user.facebook_id,
        )

        @new_user = true if authentication.new_record?

        authentication.auth_token = auth_token
        authentication.save!

        provider = Socialable::Facebook::Provider.new(authentication)
        provider.regenerate_auth_token

        authentication
      end
    end
  end
end
