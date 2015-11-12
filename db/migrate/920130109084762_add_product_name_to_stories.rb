class AddProductNameToStories < ActiveRecord::Migration
  def change
    add_column :stories, :store_id, :string
  end
end
