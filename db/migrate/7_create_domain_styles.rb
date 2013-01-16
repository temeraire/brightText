class CreateDomainStyles < ActiveRecord::Migration
  def self.up
    create_table :domain_styles do |t|
      t.integer :domain_id
      t.integer :style_id
      t.string :app_alias
      t.string :group_alias
      t.string :set_alias
      t.string :story_alias
      t.string :logo

      t.timestamps
    end
    
  
    adminStyle    = DomainStyle.create( :domain_id=> 1, :style_id => 0, :app_alias => "application", :group_alias => "story set group", :set_alias => "story set", :story_alias => "story" )
    contextStyle  = DomainStyle.create( :domain_id=> 2, :style_id => 0, :app_alias => "application", :group_alias => "story set group", :set_alias => "story set", :story_alias => "story" )
    
    adminStyle.save
    contextStyle.save      
  end


  def self.down
    drop_table :domain_styles
  end
end
