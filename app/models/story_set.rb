class StorySet < ActiveRecord::Base
  has_many :stories
  
  def category
    return "-- unassigned --" if ( category_id == nil ) 
    
    catObj = StorySetCategory.find_by_sql [ "select * from story_set_categories where id = ?", category_id ]
    return catObj[0].name unless catObj == nil || catObj.count < 1
  end
end
