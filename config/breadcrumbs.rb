crumb :root do |bright_text_application|
  if(bright_text_application.present?)
    link bright_text_application.name, admin_story_set_categories_path
  end 
end

crumb :story_set_category do |story_set_category|
  link story_set_category.name, admin_story_sets_path
  if story_set_category.bright_text_application.name.length > 19 
    story_set_category.bright_text_application.name = story_set_category.bright_text_application.name[0..19].gsub(/\s\w+\s*$/,'...')   
  end  
  parent :root, story_set_category.bright_text_application 
end

crumb :story_set do |story_set|
  link story_set.name, admin_stories_path
  if story_set.story_set_category.name.length > 19 
    story_set.story_set_category.name = story_set.story_set_category.name[0..19].gsub(/\s\w+\s*$/,'...')   
  end
  parent :story_set_category, story_set.story_set_category
end

crumb :story do |story|
 link story.name, admin_stories_path
 if story.story_set.name.length > 19 
   story.story_set.name = story.story_set.name[0..19].gsub(/\s\w+\s*$/,'...')   
 end
 parent :story_set, story.story_set
end