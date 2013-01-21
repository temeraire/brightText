class BrightTextApplication < ActiveRecord::Base
  has_many :story_set_categories, :dependent => :destroy

  validates :name,
              :uniqueness => { :message => "This name is already taken. Please select another name" },
              :presence => {:message => "Please insert a name."}
end
