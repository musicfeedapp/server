class Api::Client::V1::Users < Grape::API
  format :json

  resources :users do

    helpers do
      def current_user
        @user
      end
    end

    params do
      requires :auth_token, type: String, desc: "Auth token picked up on the user activity on the device"
    end
    post '/facebook', rabl: 'v1/users/facebook' do
      begin
        @user, options = User.find_or_create_by_facebook_auth_token(params[:auth_token])

        unless @user.present?
          throw :error, status: 403, message: ErrorSerializer.serialize(invalid_auth_token: 'Invalid facebook auth token')
        end

        options ||= {}

        RegistrationSteps.each do |step|
          step.call(@user, options)
        end

        # passing current_user object and for user.
        @user = UserAdataper.new(@user, @user)

        @new_user = options.fetch(:new_user) { false }
      rescue => boom
        Notification.notify(boom, { from: "Api::Client::V1::Users" }.merge(params))
        throw :error, status: 400, message: ErrorSerializer.serialize(@user.errors)
      end
    end

    params do
      requires :id
      optional :username,       type: String
      optional :contact_number, type: String
      optional :avatar,         type: Rack::Multipart::UploadedFile
    end
    put '/update', rabl: 'v1/users/update' do
      @user = User.find(params[:id])
      !@user.present? && throw(:error, status: 400, message: ErrorSerializer.serialize(not_found_user: 'User not found.'))
      !@user.update(username: params[:username],
                    avatar: params[:avatar],
                    contact_number: params[:contact_number]
                   ) && throw(:error, status: 400, message: ErrorSerializer.serialize(@user.errors))
    end

    helpers do
      def user_attributes
        @user_attributes ||= {
          email: params[:email],
          password: params[:password],
          name: params[:name]
        }
      end

      def warden
        request.env['warden']
      end
    end
    params do
      requires :email, type: String
      requires :password, type: String
      optional :name, type: String
    end
    post '/signup', rabl: 'v1/users/facebook' do
      begin
        @user = User.new(user_attributes.merge(login_method: "email"))
        @user.save!

        RegistrationSteps.each do |step|
          step.call(@user, {})
        end

        # passing current_user object and for user.
        @user = UserAdataper.new(@user, @user)

        @new_user = true
      rescue => boom
        Notification.notify(boom, { from: "Api::Client::V1::Users" }.merge(params))
        throw :error, status: 400, message: ErrorSerializer.serialize(@user.errors)
      end
    end

    params do
      requires :email, type: String
      requires :password, type: String
    end
    post '/signin', rabl: 'v1/users/facebook' do
      begin
        @user = User.find_by_email(params[:email])

        unless @user.present?
          throw :error, status: 400, message: ErrorSerializer.serialize(not_found_user: 'User not found.')
        end

        unless @user.valid_password?(params[:password])
          throw :error, status: 403, message: ErrorSerializer.serialize(invalid_password: 'Password is invalid.')
        end

        @user = UserAdataper.new(@user, @user)

        @new_user = false
      rescue => boom
        Notification.notify(boom, { from: "Api::Client::V1::Users" }.merge(params))
        throw :error, status: 400, message: ErrorSerializer.serialize(@user.errors)
      end
    end

    params do
      requires :id
    end

    get '/friends', rabl: 'v1/users/friends' do
      @user = User.find(params[:id])
      !@user.present? && throw(:error, status: 400, message: ErrorSerializer.serialize(not_found_user: 'User not found.'))
       @friends = @user.friends
    end

    SuccessResponse = {}

    params do
      requires :email, type: String
    end
    post '/forgot_password' do
      @user = User.find_by_email(params[:email])

      if @user.blank?
        throw :error, status: 400, message: ErrorSerializer.serialize(not_found_user: 'Not found user in the system')
      end

      UserMailer.reset_password_instructions(@user).deliver

      SuccessResponse
    end
  end # auth

end
