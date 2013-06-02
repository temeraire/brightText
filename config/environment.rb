
# Load the rails application
require File.expand_path('../application', __FILE__)


# Initialize the rails application
BrightText::Application.initialize!

#Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)   
# ActionMailer::Base.perform_deliveries = true
# ActionMailer::Base.raise_delivery_errors = true    
# ActionMailer::Base.delivery_method = :smtp
# # ActionMailer::Base.smtp_settings = {
#   :address              => "smtp.gmail.com",  
#   :port                 => 587,  
#   :user_name            => 'pavel@brighttext.com',
#   :password             => 'Duke2000',
#   :authentication       => "plain",
#   :enable_starttls_auto => true  
# }    


