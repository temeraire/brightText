class Admin::PasswordResetsController < ApplicationController
  layout "users"
  def new
  end

  def create
    user = User.find_by_email params[:email]
    user.send_password_reset if user
    redirect_to new_user_path, notice: "Email sent with password reset instructions."
  end

  def edit
    @user = User.find_by_reset_password_token! params[:id]
  end

  def update
    @user = User.find_by_reset_password_token! params[:id]
    if @user.reset_password_sent_at < 2.hours.ago
      redirect_to new_password_reset_path, alert: "Passowrd &crarr; reset has expired."
    else
      if @user.update_attributes! params[:user]
        redirect_to root_url, notice: "Password has been reset."
      else
        logger.debug "#{@user.errors}"
        render :edit
      end
    end
  end
end
