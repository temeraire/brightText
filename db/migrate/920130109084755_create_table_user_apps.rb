class CreateTableUserApps < ActiveRecord::Migration
  def change
    create_table :user_apps do |t| 
      t.belongs_to :user
      t.belongs_to :bright_text_application
      t.string :version
      t.integer :platform
      t.boolean :paid
      t.timestamps
      t.index [:user_id, :bright_text_application_id, :platform], :name => 'index_user_apps_on_user_id_and_app_id_and_platform'
    end
  end
end
