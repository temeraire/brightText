class CreateStories < ActiveRecord::Migration
  def self.up
    create_table :stories do |t|
      t.timestamps
      t.string      :name
      t.string      :description
      t.integer     :domain_id
      t.integer     :user_id
      t.integer     :story_set_id
      t.string	    :descriptor
    end
    #execute 'ALTER TABLE stories ADD COLUMN descriptor MEDIUMTEXT'
    
  end

  def self.down
    drop_table :stories
  end
end
