require 'rubygems'
require 'openssl'
require 'base64'

class Api::BrightTextApplicationsController < ActionController::Base
  def set_app_version
    @user_name = request[:user_name]
    @password = request[:password]
    @application_id = request[:application_id]
    
    data = request[:data]
    signature = request[:signature]
    
    base64_encoded_public_key = "YOUR KEY HERE"
      
    key = OpenSSL::PKey::RSA.new(Base64.decode64(base64_encoded_public_key))

    verified = key.verify( OpenSSL::Digest::SHA1.new, Base64.decode64(signature), data )
    
    if verified
      puts "data is verified"
    end   

  end
end