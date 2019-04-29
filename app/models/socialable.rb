require_relative 'socialable/avatar'
require_relative 'socialable/facebook'

module Socialable
  def self.included(base)
    base.class_eval do
      has_many :authentications, dependent: :destroy do
        def facebook
          @facebook ||= Facebook::Provider.new(self.where(provider: 'facebook').first)
        end
      end

      extend Socialable::ClassMethods
      extend Socialable::Facebook::ClassMethods
    end
  end

  include Socialable::Avatar
  include Socialable::Facebook

  module ClassMethods
    def create_user_by_auth(auth, attributes)
      user = User.find_by(email: auth.info['email'])

      unless user.present?
        user = User.create(attributes.merge(password: Devise.friendly_token[0,20]))
      end

      if user.persisted?
        # TODO: check expires_at field for other social authentications.
        user.authentications.create(auth_token:  auth.credentials[:token],
          provider:    auth.provider,
          uid:         auth.uid,
          email:       auth.info['email'],
          expires_at:  Time.at(auth.credentials[:expires_at]))
        user
      end
    end
  end

end
