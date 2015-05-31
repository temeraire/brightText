class UserMailer < ActionMailer::Base
  default :from => "no_reply@brighttext.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.password_reset.subject
  #
  def password_reset(user, app_name)
    @user = user
    @app_name = app_name
    mail :to => user.email, subject: "Password Reset"
  end
end
