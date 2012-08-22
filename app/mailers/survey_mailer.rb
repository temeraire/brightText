class SurveyMailer < ActionMailer::Base
  default :from => "pavel@brighttext.com"
  
  
  def survey_result_email( survey, quantitativeResult, qualitativeResult )
    @user = "davidw@brighttext.com"
    @questions = survey
    @numData   = quantitativeResult
    @wordData  = qualitativeResult
    Rails.logger.info("-------")
    Rails.logger.info("-------")
    Rails.logger.info(" DATA: " + @numData.to_s )
    Rails.logger.info("-------")
    Rails.logger.info(" DIGESTS: " + @wordData.to_s )
    Rails.logger.info("-------")
    Rails.logger.info("-------")
    msg = mail(:to => @user, :subject => "Survey Submitted")
    Rails.logger.info("created mail message: #{ msg.inspect } using settings: #{ msg.delivery_method.settings }" )
    return msg
  end  
end
