# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'
require 'open-uri'
require 'rexml/document'
require 'rexml/formatters/transitive'

BrightText::Application.load_tasks


namespace :migrate do

  # import a custom app from the demo server
  task :custom_app, [:app_id] do |t, args|
    BrightText::Application.initialize!
    appId = args[:app_id]
    app = BrightTextApplication.find appId
    
    puts 'importing custom data into app: ' + app.id.to_s

    # fetch the application from the demo server
    # URL: http://david.pavelmurnikov.com/bright_text_applications/3.xml
    uri = "http://david.pavelmurnikov.com/bright_text_applications/3.xml"
    
    content = open( uri ).read
    
    doc =  REXML::Document.new( content )
    
    
    # iterate over all story set categories
    doc.root.each_element( "//StoryCategory" ) do |categoryElement|  
      category = StorySetCategory.new( { :name => categoryElement.attributes["name"], :application_id => app.id, :domain_id => app.domain_id } )
      category.save()
      puts " Created Category: " + category.id.to_s
      proxy = BtProxyController.new
      
      rank = 0
      categoryElement.each_element( "StorySets/StorySet" ) do |setElement|
        rank += 1
        set = StorySet.new( {:name => setElement.attributes["name"], :category_id => category.id, :domain_id => app.domain_id, :rank => rank } )
        set.save()
        puts "  - Created Set: " + set.id.to_s
        
        setElement.each_element( "Stories/Story" ) do | storyElement |
          story = Story.new( { :name => storyElement.attributes["name"], :story_set_id => set.id, :domain_id => app.domain_id } )
          story.descriptor = proxy.xmlToJson( storyElement )          
          story.save
          puts "     -- Created Story: " + story.id.to_s
        end
      end
    end
  end

  task :style do
    BrightText::Application.initialize!
     
    Domain.all.each do | domain |
      style = DomainStyle.find_by_domain_id domain.id
      if ( style == nil )
        puts " Creating style for domain " + domain.nickname
        style = DomainStyle.new( {:domain_id => domain.id, :style_id => 1, :app_alias => "application", :group_alias => "category", :set_alias => "set", :story_alias => "story", :logo => "/static/default_logo.png" } )
        style.save
      end
    end     
  end

  task :single, [:story_id] do |t, args|
    # request a story
    BrightText::Application.initialize!
    Story.migrate_helper_import args[:story_id]
    
  end
  
  task :related, [:story_id] do |t, args|
    # request related
    
    BrightText::Application.initialize!
    Story.migrate_helper_related args[:story_id].to_i
    
  end
  
  task :run do
    BrightText::Application.initialize!
    (1...1200).each do |val|
      puts '    '
      puts ' *************   MIGRATING STORY SET  ' + val.to_s + " *************"
      
      #Story.migrate_helper_import( val )
      Story.migrate_helper_related( val )
      sleep(2)
      
    end
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