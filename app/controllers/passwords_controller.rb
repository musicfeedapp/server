class PasswordsController < Devise::PasswordsController
  protected

  def after_resetting_password_path_for(resource)
    open_app_path
  end
end