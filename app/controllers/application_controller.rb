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
end
