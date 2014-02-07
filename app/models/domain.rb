require 'digest/sha1'

class Domain < ActiveRecord::Base
  has_one :user

  validates_uniqueness_of :nickname, :scope => :id
  validates_length_of :nickname, :within => 3..40
  validates_length_of :password, :within => 4..40 unless :password == nil
  validates_presence_of :nickname, :email,  :password, :password_confirmation
  validates_uniqueness_of :nickname, :email
  validates_confirmation_of :password
  validates_format_of :email, :with => /\A(|(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6})\z/i, :message => "Invalid email"

  attr_protected :id, :salt

  attr_accessor :password, :password_confirmation


  def self.random_string(len)
    #generate a random password consisting of strings and digits
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end


  def password= (p)
    if ( p != "******" && !p.empty?)
      @password = p
      self.salt = Domain.random_string(10) unless self.salt?
      self.pass = Domain.encrypt(@password, self.salt)
      puts ' generated pass: ' + self.pass
    end
  end

  def password
    logger.info("  what the hell is the pass set to???  " + pass ) unless pass == nil;
    return "******" unless pass == nil || pass.empty?
  end

  def password_confirmation
    return "******" unless pass == nil || pass.empty?
  end

  def self.encrypt(p, salt)
    Digest::SHA1.hexdigest(p+salt)
  end


  def self.authenticate(acct, p)
    domain = find(:first, :conditions=>["nickname = ?", acct])
    return nil if domain.nil?
    logger.info( " comparing " + Domain.encrypt(p, domain.salt) )
    logger.info( " with " + domain.pass )

    logger.info( "generated pass: " + domain.pass)
    return domain if Domain.encrypt(p, domain.salt) == domain.pass
    nil
  end


  def send_new_password
    new_pass = Domain.random_string(10)
    self.password = self.password_confirmation = new_pass
    self.save
    #Notifications.deliver_forgot_password(self.email, self.nickname, new_pass)
  end
end

