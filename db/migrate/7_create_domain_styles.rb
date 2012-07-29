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
  end

  def self.down
    drop_table :domain_styles
  end
end
