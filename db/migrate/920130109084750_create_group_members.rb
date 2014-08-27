class CreateGroupMembers < ActiveRecord::Migration
  def change
    create_table :group_members do |t|
      t.string :email
      t.belongs_to :group
      t.belongs_to :user
      t.timestamps
      t.index :email
    end
  end
end
