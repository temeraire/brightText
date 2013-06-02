class User < ActiveRecord::Base
  belongs_to :domain
  attr_accessor :password
  
  before_save :encrypt_password, :set_domain

  validates :name, :email, :presence => {:message => "Please insert a name."}
  validates :password, 
                :presence => {:message => "Please insert password(minimum 4 charecters long)."},
                #:confirmation => true, 
                :length => {:minimum => 4}
  validates :email, :format => { :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "Please insert a valid email." }
  validates :email, uniqueness: true

  validates :password, :confirmation => true, :on => :create
  validates :password, :confirmation => true, :on => :update, :unless => lambda{ |user| user.password.blank? }

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
    user = where("email = :name", :name => name ).first
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
    end
  end

  def send_password_reset
    generate_token :reset_password_token
    self.reset_password_sent_at = Time.zone.now
    save! validate: false
    UserMailer.password_reset(self).deliver
  end

  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
  end
end
