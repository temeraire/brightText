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
          
          @user_app = UserApp.where(:user_id=>@user.id, :bright_text_application_id=>application_id).first
          
          if @user_app.present?
            if platform == "ios" && @user_app.ios?
              render :json=> { :success => "true"}
            elsif platform == "android" && @user_app.android?
              render :json=> { :success => "true"}
            else
              render :json=> { :success => "false", :message=>"You are not registered for this platform!"}      
            end
          else
            render :json=> { :success => "false", :message=>"You are not registered for this platform!"}
          end
        else
          render :json=> { :success => "false", :message=>"Username/password does not match!"}      
          
        end        
      }
    end
  end
  
  def register_user
    
    @user_name = request[:user_name]
    @password = request[:password]
    @application_id = request[:application_id]
    
    @bt_application = BrightTextApplication.find(@application_id)
    @user = User.find_by_email(@user_name);      
      
    respond_to do |format|
      format.json {   
        if(@user.blank?)
          @user = User.new
          @user.email = @user_name;
          @user.password = @password
          @user.domain_id = @bt_application.domain_id
          @user.customer!
          @user.group = Group.new
          @user.group.name = "Apologies"

          if @user.save
            GroupMember.where(:email => @user.email).update_all(:user_id=>@user.id)
            render :json=> { :success => "true", :message=>"User is registered successfully!!"} 
          else          
            render :json=> { :success => "false", :message=>"Error is registering the user!"}      
          end 
        else
          render :json=> { :success => "false", :message=>"User is already registered!"}           
        end
      }
    end
  end
end