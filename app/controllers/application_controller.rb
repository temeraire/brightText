class ApplicationController < ActionController::Base
  protect_from_forgery
  def login_required
    if session[:domain]
      return true
    end
    flash[:warning]='Please login to continue'
    session[:return_to]=request.request_uri
    redirect_to "/index.html"
    return false 
  end

  def current_user
    session[:domain]
  end
  
  def get_first_application_id
    BrightTextApplication.where(:domain_id => session[:domain].id).order(:name).first.id.to_s
  end
  
  def find_application
    application = BrightTextApplication.find_by_id session[:br_application_id]
    application = BrightTextApplication.find_by_id get_first_application_id if application.blank?
    session[:br_application_id] = application.blank? ? nil : application.id
    application
  end
end
