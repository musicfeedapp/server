class UserMailer < ApplicationMailer
  include SendGrid

  sendgrid_category :use_subject_lines
  sendgrid_enable   :ganalytics, :opentrack, :templates

  def welcome(user_id)
    user = User.find(user_id)

    sendgrid_template_id '046fba83-741b-4e24-b619-a6dd8a0047b1'
    sendgrid_category 'Welcome'
    sendgrid_recipients [user.email]
    sendgrid_substitute 'user_first_name', [user.first_name]
    sendgrid_substitute 'subject', ['Welcome to Musicfeed!']

    mail to: user.email,
      subject: "Welcome to Musicfeed!",
      bcc: 'hola@musicfeed.co'
  end

  def reset_password_instructions(user)
    token = user.send(:set_reset_password_token)

    sendgrid_template_id '3d2147b8-2ab7-431f-96f7-07f16d5fd36e'
    sendgrid_category 'Forgot Password'
    sendgrid_recipients [user.email]
    sendgrid_substitute 'user_first_name', [user.first_name]
    sendgrid_substitute 'password_reset_link', ["http://musicfeed.rubyforce.co/users/password/edit?reset_password_token=#{token}"]
    sendgrid_substitute 'subject', ['Forgot Password']

    mail to: user.email,
      subject: 'Forgot Password'
  end
end
