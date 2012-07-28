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
    
    Domain.all.each do | domain |
      puts " Creating style for domain " + domain.nickname
      style = DomainStyle.new( {:domain_id => domain.id, :style_id => 1, :app_alias => "application", :group_alias => "category", :set_alias => "set", :story_alias => "story", :logo => "/static/default_logo.png" } )
      style.save
    end
    
  end

  def self.down
    drop_table :domain_styles
  end
end
