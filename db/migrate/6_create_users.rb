class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name
      t.integer :domain_id
      t.string :password
      t.string :nickname

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
