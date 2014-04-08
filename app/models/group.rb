class Group < ActiveRecord::Base
  has_many :group_members, autosave: true
end
