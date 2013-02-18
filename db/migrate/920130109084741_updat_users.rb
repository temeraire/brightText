class UpdatUsers < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.rename :password, :password_salt
      t.string :email
      t.string :password_hash
    end
  end

  def self.down
    change_table :users do |t|
      t.rename :password_salt, :password
      t.remove :email
      t.remove :password_hash
    end
  end
end
