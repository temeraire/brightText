crumb :campaign do |story_set|
  if(story_set.present?)
    link story_set.name, admin_stories_path
  end
end

crumb :action do |story|
  if(story.present?)
    link story.name, admin_stories_path
    if story.story_set.present? && story.story_set.name.length > 19 
      story.story_set.name = story.story_set.name[0..19].gsub(/\s\w+\s*$/,'...')   
    end
    parent :campaign, story.story_set
  end
  
end
