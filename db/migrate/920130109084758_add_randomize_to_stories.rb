class AddRandomizeToStories < ActiveRecord::Migration
  def change
	add_column :stories, :randomize, :boolean, :default=>false
  end
end
