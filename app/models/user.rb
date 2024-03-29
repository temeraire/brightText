class User < ActiveRecord::Base
  
  enum user_type: [ :customer, :moderator, :admin ]
  belongs_to :domain
  has_one :group, autosave: true
  has_many :groups, through: :group_members
  
  attr_accessor :password
  attr_accessible :name,:lastname, :email, :password, :password_confirmation, :user_type

  before_save :encrypt_password, :set_domain

  validates :email, :presence => true
  validates :password,
                :presence => {:message => "Please insert password(minimum 4 charecters long)."},
                #:confirmation => true,
                :length => {:minimum => 4}
  validates :email, :format => { :with => /\A(|(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6})\z/i, :message => "Please insert a valid email." }
  validates :email, :uniqueness => { :scope => :bright_text_application_id, :message => "This email is already registered. Please use your username and password to login." }

  validates :password, :confirmation => true, :on => :create
  validates :password, :confirmation => true, :on => :update, :unless => lambda{ |user| user.password.blank? }

  def set_domain
    unless domain_id.present?
      self.domain_id = Domain.find_by_name("ContextIT").id
    end
  end

  def encrypt_password
    if password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, self.password_salt)
    end
  end

  def self.authenticate_user(name, password, bright_text_application_id)
    user = where("email = :name AND bright_text_application_id = :bright_text_application_id", :name => name, :bright_text_application_id => bright_text_application_id).first
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
    end
  end

  def self.authenticate_admin(name, password)
    user = where("email = :name", :name => name).first
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
    end
  end


  def send_password_reset(app_name)
    generate_token :reset_password_token
    self.reset_password_sent_at = Time.zone.now
    save! validate: false
    UserMailer.password_reset(self, app_name).deliver
  end

  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
  end
end
