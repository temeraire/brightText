class Apologywiz::SessionController < ApologywizController
  before_filter :login_required, :except => [:create]
  
  
  def create
    #if request.post?
      @user = params[:username]
      @pass = params[:password] 
      @domain = Domain.authenticate( @user, @pass )
      
      if @domain
        session[:domain] = @domain
        session[:style]  = DomainStyle.find_by_domain_id @domain.id
      
        if @domain.id == 1
          redirect_to "/domains"
        else
          redirect_to "/bright_text_applications"
        end
      
      else
        redirect_to "/index.html#2"
      end

=begin
      render :js => @result  #always return the json respose
      headers['content-type']='text/javascript';  
    #else
    #  redirect_to "/index.html#1"
    #end
=end

  end
  
  def destroy
    #session[:domain] = nil
    #session[:style] = nil
    reset_session
    redirect_to "/"
  end

end
