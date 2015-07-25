require 'digest/sha1'

class Domain < ActiveRecord::Base
  has_one :user

  validates :name,
    presence: true,
    length: { in: 3..40 },
    uniqueness: true

  validates :email,
    presence: true,
    :format => { :with => /\A(|(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6})\z/i, :message => "Please insert a valid email." },
    :uniqueness => true

  attr_accessible :id, :name, :email, :enabled, :privileged, :self_created, :owner_domain_id

  def self.random_string(len)
    #generate a random password consisting of strings and digits
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
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
    #Notifications.deliver_forgot_password(self.email, self.name, new_pass)
  end
end

