class StoryAuthor < ActiveRecord::Base
  belongs_to :user # foreign_key is user_id
  belongs_to :story # foreign_key is story_id
end
