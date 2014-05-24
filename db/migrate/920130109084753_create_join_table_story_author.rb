class CreateJoinTableStoryAuthor < ActiveRecord::Migration
  def change
    create_join_table :stories, :users, table_name: :story_authors do |t|
      t.index [:story_id, :user_id]
      t.timestamps
      # t.index [:user_id, :story_id]
    end
  end
end
