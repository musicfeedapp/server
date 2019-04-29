module Socialable
  module Avatar

    def profile_image
      @profile_image ||= ProfileImage.new(self)
      @profile_image.url
    end

    require 'delegate'

    class ProfileImage < SimpleDelegator
      include ActionView::Helpers::AssetUrlHelper

      attr_reader :user

      def initialize(user)
        @user = user
      end

      def __getobj__
        @user
      end

      def url
        if @user.avatar?
          avatar.url(:thumb)
        elsif @user.facebook_link? # for email signedup users we are setting ext_id as facebook_id so have to check on facebook link
          "http://graph.facebook.com/#{facebook_id}/picture?type=large"
        else
          nil
        end
      end
    end
  end # Avatar

end
