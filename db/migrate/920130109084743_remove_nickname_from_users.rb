class RemoveNicknameFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :nickname
  end

  def self.down
    add_column :users, :nickname, :string
  end
end
