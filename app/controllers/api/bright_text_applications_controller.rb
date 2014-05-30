require 'rubygems'
require 'openssl'
require 'base64'

class Api::BrightTextApplicationsController < ActionController::Base
  def set_app_purchase
    @user_name = request[:user_name]
    @password = request[:password]
    @application_id = request[:application_id]
    
    data = request[:data]
    signature = request[:signature]
    
    base64_encoded_public_key = "YOUR KEY HERE"
      
    key = OpenSSL::PKey::RSA.new(Base64.decode64(base64_encoded_public_key))

    verified = key.verify( OpenSSL::Digest::SHA1.new, Base64.decode64(signature), data )
    
    
    respond_to do |format|
      if verified
        puts "data is verified"
        format.json {render :json=> { :success => "true"} }
      else
        puts "data is NOT verified"
        format.json {render :json=> { :success => "false"} }        
      end
    end
      

  end
end