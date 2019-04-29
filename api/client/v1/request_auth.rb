module RequestAuth

  def self.included(base)
    base.class_eval do
      before { authenticate_user! }
      params do
        requires :email, type: String
        requires :authentication_token, type: String
        optional :device_id, type: String
        optional :anonymous_mode, type: String
      end
    end
  end

end

