class AddProductNameToStories < ActiveRecord::Migration
  def change
    add_column :stories, :product_name, :string
  end
end
