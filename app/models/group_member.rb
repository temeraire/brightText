class GroupMember < ActiveRecord::Base
  belongs_to :group
  belongs_to :user

  attr_accessible :email

end
