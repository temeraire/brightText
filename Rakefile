# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'
BrightText::Application.load_tasks


namespace :migrate do

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