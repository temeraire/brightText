class Relext::PasswordResetsController < RelextController
  layout "relext"
  def new
  end

  def create
    @user = User.where(:email=> params[:email], :bright_text_application_id => BrightTextApplication.where(:name=>"Relext").first.id).first
    app_name = "Relext"
    @user.send_password_reset(app_name) if @user
    
    respond_to do |format|
      format.js
    end
    #redirect_to relext_login_path, notice: "Email sent with password reset instructions."
  end

  def edit
    @user = User.find_by_reset_password_token! params[:id]
  end

  def update
    @user = User.find_by_reset_password_token! params[:id]
    if @user.reset_password_sent_at < 2.hours.ago
      redirect_to new_relext_password_reset_path, notice: "Passowrd reset has expired."
    else
      if @user.update_attributes! params[:user]
        redirect_to relext_login_path, notice: "Password has been reset."
      else
        logger.debug "#{@user.errors}"
        render :edit
      end
    end
  end
end
