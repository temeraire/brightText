class StorySetCategory < ActiveRecord::Base
  def application
    return "-- unassigned --" if ( application_id == nil ) 
    
    appObj = BrightTextApplication.find_by_sql [ "select * from bright_text_applications where id = ?", application_id ]
    return appObj[0].name unless appObj == nil || appObj.count < 1
  end
  
  before_save :set_rank
  
  def set_rank
    if self.rank.blank? || self.rank == 0 || self.application_id_changed?
      self.rank = 1 + StorySetCategory.maximum(:rank, :conditions => ["application_id = ?", self.application_id]).to_i 
    end
  end
end
