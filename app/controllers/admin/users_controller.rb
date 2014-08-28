class Admin::UsersController < ApplicationController
  
  def new_session
    reset_session
    @user = User.new
    redirect_to "/admin/index.html"
  end

  def authenticate
    if (@user = User.authenticate params[:user][:email], params[:user][:password])
      log_in! @user
      #redirect_to apologywiz_stories_path, notice: "Logged in!"
      if @user.admin?
        redirect_to admin_domains_path, status: :found #"/admin/domains"
      elsif @user.moderator?
        if session[:domain].name=="Advocacy"
          redirect_to admin_story_sets_path, status: :found #"/admin/domains"
        else
          redirect_to admin_bright_text_applications_path, status: :found #"/admin/bright_text_applications"
        end
        
        redirect_to admin_bright_text_applications_path, status: :found #"/admin/bright_text_applications"
      else
        redirect_to admin_login_path
      end
    else
      @user = User.new
      flash.now[:error] = "Email or password is invalid"
      redirect_to "/admin/index.html"
    end
  end

  def destroy_session
    session[:domain] = nil
    session[:style] = nil
    reset_session
    redirect_to admin_login_path
  end
end
