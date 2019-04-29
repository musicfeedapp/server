module Api::Client::V1::Auth
  # It should always come with before filter to check access to the
  # api based on email and authentication token.
  def current_user
    @current_user
  end

  def authentication_token
    params[:authentication_token]
  end

  def email
    params[:email]
  end

  def authenticable?
    email.present? && authentication_token.present?
  end

  def device_id
    params[:device_id]
  end

  def anonymous_mode
    params[:anonymous_mode]
  end

  def is_anonymous_mode?
    request.get? && device_id.present? && anonymous_mode.present?
  end

  # success: @current_user
  # failed:  status: 403
  def authenticate_user!
    if is_anonymous_mode?
      if user = User.find_by_device_id(device_id)
        return @current_user = user
      else
        throw :error, status: 403, message: ErrorSerializer.serialize(not_found_user: 'Not found user in the system')
      end
    end

    return unless authenticable?

    # We are using user's email because of possible timing attacks to
    # the generated authentication token.
    if user = User.find_by_email(email)
      # Compare passed and user's token if email exists in the
      # system.
      if Devise.secure_compare(user.authentication_token, authentication_token)
        @current_user = user
      else
        throw :error, status: 403, message: ErrorSerializer.serialize(invalid_api_token: 'You are using the invalid token')
      end
    else
      throw :error, status: 403, message: ErrorSerializer.serialize(not_found_user: 'Not found user in the system')
    end
  end
end

