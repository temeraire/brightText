class AddBrighttextToStories < ActiveRecord::Migration
  def change
	add_column :stories, :brighttext, :boolean, :default=>true
  end
end