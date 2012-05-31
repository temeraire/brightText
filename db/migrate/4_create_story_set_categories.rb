class CreateStorySetCategories < ActiveRecord::Migration
  def self.up
    create_table :story_set_categories do |t|
      t.string :name
      t.string :description
      t.integer :domain_id
      t.integer :user_id
      t.integer :application_id
      
      t.timestamps
    end
  end

  def self.down
    drop_table :story_set_categories
  end
end
