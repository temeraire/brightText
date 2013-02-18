class User < ActiveRecord::Base
  belongs_to :domain
  attr_accessor :password
  
  before_save :encrypt_password, :set_domain
  
  validates :name, :presence => {:message => "Please insert a name."}
  validates :nickname, 
                :presence => {:message => "Please insert a nickname(minimum 4 charecters long)."}, 
                :uniqueness => {:message => "Nickname is already registered. Choose new one."}, 
                :length => {:minimum => 3, :message => "Minimum 3 charecters are required for nickname."}
  validates :password, 
                :presence => {:message => "Please insert password(minimum 4 charecters long)."},
                #:confirmation => true, 
                :length => {:minimum => 4, :message => "Minimum 4 charecters are required for password."}
  validates :email, 
                :format => { :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "Please insert a valid email." }

  def set_domain
    unless domain_id.present?
      self.domain_id = Domain.find_by_nickname("ContextIT").id
    end 
  end
  
  def encrypt_password
    if password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, self.password_salt)
    end
  end
  
  
  def self.authenticate(name, password)
    user = where("email = :name OR nickname = :name", :name => name ).first
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
    end
  end
end
