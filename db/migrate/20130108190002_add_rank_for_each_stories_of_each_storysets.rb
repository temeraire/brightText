class AddRankForEachStoriesOfEachStorysets < ActiveRecord::Migration
  def self.up
    story_sets = StorySet.all
    story_sets.each do |set|
      set.stories.each_with_index do |story, i|
        story.update_attributes(:rank => i + 1)
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, "Irreversable Migration AddRankForEachStoriesOfEachStorysets!"
  end
end
