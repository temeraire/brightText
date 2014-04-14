class AddPublicToStories < ActiveRecord::Migration
  def change
    add_column :stories, :public, :boolean, :default=>false
  end
end
