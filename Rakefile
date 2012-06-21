# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'
BrightText::Application.load_tasks


namespace :migrate do



  task :single, [:story_id] do |t, args|
    # request a story
    BrightText::Application.initialize!
    storyId = args[:story_id]
    
    existingStory = Story.find_by_id( storyId )
    if existingStory
      raise 'story exists'
    end
    
    uri = "http://test.contextit.com/ProcessTemplateRequest.aspx?cmd=GETXML&validationKey=75&storyID=" + storyId + "&doNotEncrypt=TRUE"
    doc = REXML::Document.new(open(uri).read)
    puts ' XML\n' + doc.to_s
    puts '\n\n\n\n\n'

    
    # convert to json
    
    proxy = BtProxyController.new
    result = proxy.xmlToJson( doc )
    
    puts ' JSON\n' + result
    puts '\n\n\n\n\n'    
    
    # create a local db entry
    
    story = Story.new({ :id=>storyId.to_i, :descriptor => result })
    
    # save
    story.save
    
    puts '\n\nstory created.  local story id: ' + story.id.to_s
  end
  
  task :related, [:story_id] do |t, args|
    # request related
   
    
    BrightText::Application.initialize!
    storyId = args[:story_id]
    
    existingStory = Story.find_by_id( storyId )
    if existingStory == nil
      raise 'story does not exist'
    end    
    
    
    uri = "http://test.contextit.com/ProcessTemplateRequest.aspx?cmd=getrelatedstories&validationKey=75&storyID=" + storyId + "&doNotEncrypt=TRUE"
    doc = REXML::Document.new(open(uri).read)
    puts ' XML\n' + doc.to_s
    puts '\n\n\n\n\n'

    
    storyIds = [];
    doc.root.each_element( "//StoryId" ){ |e|  storyIds << e.text.to_i } 
    
    puts ' STORIES: ' + storyIds.to_s
    puts '\n\n\n\n\n'    
    
    existingSet = nil
    
    # if more than 0 find whether story set was created for those stories
    if storyIds.count > 0 
      queryParams = []
      storyIds.each do | id |
        queryParams << '?'
      end
    
      existingSetId = StorySet.find_by_sql ["select story_set_id from stories where stories.id in (" + queryParams.join(",") + " ) group by story_set_id", storyIds ].flatten
      raise ' too many story sets!!! ' if existingSetId.count > 1
      
      puts '  ** story set count ** ' + existingSetId.count.to_s
      
      existingSet = StorySet.find_by_id ( existingSetId[0].story_set_id ) if existingSetId.count == 1
    end
    
    #  create story set if not
    if ( existingSet == nil )
      puts 'creating new story set'
      existingSet = StorySet.new
      existingSet.save
    end
    
    
    #  asocciate story with story sets
    existingStory.story_set_id = existingSet.id
    existingStory.save
    #  done
    
    puts ' asocciated story set id ' + existingStory.story_set_id.to_s + ' with story ' + existingStory.id.to_s
    
  end
  
  task :run do
  
  end
  

  task :retarded, [:story_id] do |t, args|
  
    # request a story
    BrightText::Application.initialize!
    storyId = args[:story_id].to_i
    
    begin
      story = Story.new
      story.save
      puts ' created dummy story ' + story.id.to_s
    end while story.id < storyId-1
  end  
  
  

end