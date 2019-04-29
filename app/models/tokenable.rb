module Tokenable

  def self.included(base)
    base.class_eval do
      before_save :ensure_authentication_token

      def ensure_authentication_token
        if authentication_token.blank?
          # TODO: remove it in production!
          if self.email == "alex.korsak@gmail.com"
            self.authentication_token = self.email
          else
            self.authentication_token = generate_authentication_token
          end
        end
      end

      private

      def generate_authentication_token
        loop do
          token = Devise.friendly_token
          break token unless User.find_by_authentication_token(token)
        end
      end
    end
  end

end

