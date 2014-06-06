class CreateJoinTableUserApps < ActiveRecord::Migration
  def change
    create_join_table :users, :bright_text_applications, table_name: :user_apps do |t|      
      t.string :version
      t.integer :platform
      t.boolean :paid
      t.timestamps
      t.index [:user_id, :bright_text_application_id, :platform],:unique => true, :name => 'index_user_apps_on_user_id_and_app_id_and_platform'
    end
  end
end
