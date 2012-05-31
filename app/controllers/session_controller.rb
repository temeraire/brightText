class SessionController < ApplicationController
  before_filter :login_required, :except => [:create]
  
  
  def create
    #if request.post?
      @user = params[:username]
      @pass = params[:password] 
      @domain = Domain.authenticate( @user, @pass )
      
      if @domain
        session[:domain] = @domain
      
        if @domain.id == 1
          redirect_to "/domains"
        else
          redirect_to "/stories"
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

end
