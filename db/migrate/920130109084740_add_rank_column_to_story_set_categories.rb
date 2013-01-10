class AddRankColumnToStorySetCategories < ActiveRecord::Migration
  def self.up
    add_column :story_set_categories, :rank, :integer
  end

  def self.down
    remove_column :story_set_categories, :rank
  end
end
