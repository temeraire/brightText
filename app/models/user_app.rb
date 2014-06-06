class UserApp < ActiveRecord::Base
  belongs_to :user # foreign_key is user_id
  belongs_to :bright_text_application# foreign_key is bright_text_application_id
  
  enum platform: [ :ios, :android, :black_berry, :windows_phone ]
  
  attr_accessible :user_id, :bright_text_application_id, :platform, :version, :paid
end
