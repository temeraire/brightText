class AddStoreIdToStories < ActiveRecord::Migration
  def change
    add_column :stories, :store_id, :string
  end
end
