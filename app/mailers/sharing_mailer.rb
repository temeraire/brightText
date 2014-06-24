class SharingMailer < ActionMailer::Base
  default :from => "no_reply@brighttext.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.password_reset.subject
  #
  def invitation(sender, email)    
    @sender = sender
    mail :to => email, subject: "Inivitation"
  end
end
