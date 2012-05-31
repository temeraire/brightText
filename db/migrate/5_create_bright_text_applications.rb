class CreateBrightTextApplications < ActiveRecord::Migration
  def self.up
    create_table :bright_text_applications do |t|
      t.integer :domain_id
      t.integer :user_id
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :bright_text_applications
  end
end
