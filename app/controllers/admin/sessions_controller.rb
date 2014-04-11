class Admin::SessionsController < ApplicationController
  #before_filter :login_required, :except => [:new, :create]

  def new
    reset_session
    redirect_to "/admin/index.html"
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
        redirect_to admin_domains_path, status: :found #"/admin/domains"
      else
        redirect_to admin_bright_text_applications_path, status: :found #"/admin/bright_text_applications"
      end

    else
      redirect_to admin_login_path
    end

  end

  def destroy
    session[:domain] = nil
    session[:style] = nil
    reset_session
    redirect_to "/admin/login"
  end

end
