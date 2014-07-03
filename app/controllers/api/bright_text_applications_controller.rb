require 'rubygems'
require 'openssl'
require 'base64'

class Api::BrightTextApplicationsController < ActionController::Base
  def set_app_purchase
    @user_name = request[:user_name]
    @password = request[:password]
    @application_id = request[:application_id]
    @platform = request[:platform]
    @version = request[:version]
    
    format = request[:format]
    data = request[:data]
    signature = request[:signature]    
    
    respond_to do |format|
      format.json {  
        verified = false
        if (@user = User.authenticate @user_name, @password)    
          
          @user_app = UserApp.new
          @user_app.user_id = @user.id
          @user_app.bright_text_application_id = @application_id
          @user_app.version = @version        
          if(@platform=="ios")
            @user_app.ios!
          else
            base64_encoded_public_key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAjongjEeaw8uutBOqxoG/elOXyfsKhC4UzagKV9fWcii0d5bItcJNhsfm0aCeZub1RUDlcC25J+EO5t9TO7+Z8aI08gQxFYFRnu7ateyt/7oA6w23rFOWzFWToollCaD7Tq2XlA5DVdmaZcIl8lQnq/PnGV72S47URmcArrLOlUMmiBV3/mSa74qbl7AwzTdDWs7AGr/wQIIDxYtrSh5GiDyKU9sJuxWe+Lih/6a92d5cZcqrhc4/ULom/A5o09NK4405xi+SXpaxrxWbK/9tNaBrlJiWXoU3ese0OYJc7nxv5FDmaWA8GzoS9242NWurJhtNRqyzQQVlW+VhwljWawIDAQAB"
            key = OpenSSL::PKey::RSA.new(Base64.decode64(base64_encoded_public_key))
            verified = key.verify( OpenSSL::Digest::SHA1.new, Base64.decode64(signature), data )        
            @user_app.android!
          end
          @user_app.paid = verified
          @user_app.save

          if verified
            puts "data is verified"
            render :json=> { :success => "true"} 
          else
            puts "data is NOT verified"
            render :json=> { :success => "false", :message=>"Purchase data is not valid!"}      
          end
        else
          render :json=> { :success => "false", :message=>"Username/password does not match!"} 
          
        end        
      }
    end
  end
  
  def verify_receipt (receipt_data, app_id)

    logger.info "APP_STORE_URL:" + APP_STORE_URL

    # Get the magazines shared secret
    shared_secret = BrightTextApplication.find(app_id).itunes_shared_secret

    if shared_secret.nil? or shared_secret.blank?
      # Invalid magazine
      logger.info "Shared secret does not exist or does not match iTunes shared secret!"
      result = false
    else
      logger.info "Verifying receipt from Apple now!"
      # Verify receipt with apple based on magazine status, and save results
      data = { "receipt-data" => receipt_data, "password" => shared_secret }
      request = Typhoeus::Request.new(APP_STORE_URL, method: :post, body: data.to_json )
      request.run
      result = JSON.parse(request.response.body).with_indifferent_access
      logger.info "Result from verification: #{result[:status]}"
    end
    return result
  end
end