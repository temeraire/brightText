namespace :db do
  desc "Add rank to stories"
  task :add_rank => :environment do
    stories = Story.all :order => :story_set_id
    set_id = -1
    rank = 0
    stories.each do |story|
      if story.story_set_id != set_id
        rank = 1
        story.rank = rank
        set_id = story.story_set_id
      end
      story.save!
    end
  end
end