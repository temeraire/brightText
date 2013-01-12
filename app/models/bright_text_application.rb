class BrightTextApplication < ActiveRecord::Base
  has_many :story_set_categories, :dependent => :destroy
end
