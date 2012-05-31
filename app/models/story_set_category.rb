class StorySetCategory < ActiveRecord::Base
  def application
    return "-- unassigned --" if ( application_id == nil ) 
    
    appObj = BrightTextApplication.find_by_sql [ "select * from bright_text_applications where id = ?", application_id ]
    return appObj[0].name unless appObj == nil || appObj.count < 1
  end
end