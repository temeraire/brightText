class CreateStorySets < ActiveRecord::Migration
  def self.up
    create_table :story_sets do |t|
      t.string :name
      t.integer :domain_id
      t.integer :user_id
      t.integer :category_id
      t.integer :rank

      t.timestamps
    end
    
    defaultSet = StorySet.create( {:name=> "Default", :domain_id => 2})
    defaultSet.save    
  end

  def self.down
    drop_table :story_sets
  end
end
