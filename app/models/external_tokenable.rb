module ExternalTokenable

  def self.included(base)
    base.class_eval do
      before_save :ensure_external_tokenable

      def ensure_external_tokenable
        if ext_id.blank?
          if self.email == "alex.korsak@gmail.com"
            self.ext_id = self.email
          else
            self.ext_id = generate_external_tokenable

            # for email signed up users we don't have facebook_id
            # and we are using facebook_id almost at all the places in our queries
            # as for anonymous user name will not exist
            if self.facebook_id.blank? && self.name.present?
              self.facebook_id = self.ext_id 
            end
          end
        end
      end

      private

      def generate_external_tokenable
        loop do
          token = Devise.friendly_token
          break token unless User.find_by_ext_id(token)
        end
      end
    end
  end

end
