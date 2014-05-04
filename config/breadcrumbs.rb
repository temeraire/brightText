crumb :root do
  link "Home", admin_bright_text_applications_path
end

crumb :bright_text_application do |bright_text_application|
 link bright_text_application.name, admin_story_set_categories_path
 parent :root
end

crumb :story_set_category do |story_set_category|
 link story_set_category.name, admin_story_sets_path
 parent :bright_text_application, story_set_category.bright_text_application 
end

crumb :story_set do |story_set|
 link story_set.name, admin_stories_path
 parent :story_set_category, story_set.story_set_category
end

crumb :story do |story|
 link story.name, admin_stories_path
 parent :story_set, story.story_set
end