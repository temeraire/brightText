class SurveyMailer < ActionMailer::Base
  default :from => "pavel@brighttext.com"
  
  
  def survey_result_email( survey, quantitativeResult, qualitativeResult )
    @user = "pavel@pavelmurnikov.com"
    @questions = survey
    @numData   = quantitativeResult
    @wordData  = qualitativeResult
    mail(:to => @user, :subject => "Survey Submitted")
  end  
end
