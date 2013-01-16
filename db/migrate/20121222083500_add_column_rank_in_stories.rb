class AddColumnRankInStories < ActiveRecord::Migration
  def self.up
    add_column :stories, :rank, :integer
  end

  def self.down
    remove_column :stories, :rank
  end
end
