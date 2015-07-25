class SharingMailer < ActionMailer::Base
  default :from => "no_reply@brighttext.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.password_reset.subject
  #
  def invitation(sender, email, app_name)    
    @sender = sender
    @app_name = app_name
    mail :to => email, subject: "Invitation"
  end
  
  def invitation_registered(sender, receiver, app_name)    
    @sender = sender
    @receiver = receiver
    @app_name = app_name
    mail :to => receiver.email, subject: "Invitation"
  end
end
