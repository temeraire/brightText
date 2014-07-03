require 'rubygems'
require 'openssl'
require 'base64'

class Api::UsersController < ActionController::Base
  def is_paid_user
    user_name = request[:user_name]
    password = request[:password]
    application_id = request[:application_id]
    platform = request[:platform]       
    
    respond_to do |format|
      format.json {  
        if (@user = User.authenticate user_name, password)    
          
          @user_app = UserApp.where(:user_id=>@user.id, :bright_text_application_id=>application_id)
          
          if @user_app.platforms[platform]
            render :json=> { :success => "true"} 
          else
            render :json=> { :success => "false", :message=>"You are not registered for this platform!"}      
          end
        else
          render :json=> { :success => "false", :message=>"Username/password does not match!"}      
          
        end        
      }
    end
  end
end