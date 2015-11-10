class Wordslider::SessionController < WordsliderController
  #before_filter :login_required, :except => [:new, :create]

  def new
    reset_session
    redirect_to "/aplogywiz/index.html"
  end

  def create
    #if request.post?
    @user = params[:username]
    @pass = params[:password]
    puts @user
    @domain = Domain.authenticate( @user, @pass )

    if @domain
      session[:domain] = @domain
      session[:style]  = DomainStyle.find_by_domain_id @domain.id

      if @domain.id == 1
        redirect_to wordslider_domains_path, status: :found #"/admin/domains"
      else
        redirect_to  wordslider_bright_text_applications_path, status: :found #"/admin/bright_text_applications"
      end

    else
      redirect_to wordslider_login_path
    end

  end

  def destroy
    session[:domain] = nil
    session[:style] = nil
    reset_session
    redirect_to wordslider_login_path
  end 

  def new_session
    reset_session
    @user = User.new
  end

  def authenticate
    @bt_application = BrightTextApplication.where(:name=>"WordSlider").first
    if (@user = User.authenticate_user params[:user][:email], params[:user][:password], @bt_application)
      log_in! @user
      redirect_to wordslider_stories_path, notice: "Logged in!"
    else
      @user = User.new
      flash.now[:error] = "Email or password is invalid"
      render 'new_session', layout: "wordslider"
    end
  end

  def destroy_session
    session[:domain] = nil
    session[:style] = nil
    reset_session
    redirect_to wordslider_login_path
  end

end
