class SurveyMailer < ActionMailer::Base
  default :from => "no_reply@brighttext.com"
  
  
  def survey_result_email( survey, quantitativeResult, qualitativeResult, meta )
    @user = "davidw@brighttext.com"
    @questions = survey
    @numData   = quantitativeResult
    @wordData  = qualitativeResult
    @meta      = meta
    msg = mail(:to => @user, :subject => "Survey Submitted")
    Rails.logger.info("created mail message: #{ msg.inspect } using settings: #{ msg.delivery_method.settings }" )
    return msg
  end  
end
