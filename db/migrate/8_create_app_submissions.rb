class CreateAppSubmissions < ActiveRecord::Migration
  def self.up
    create_table :app_submissions do |t|
      t.integer :bright_text_application_id
      t.integer :domain_id
      t.text :story_set_values
      t.text :story_set_digests
      t.text :submission_metadata

      t.timestamps
    end
    execute 'ALTER TABLE app_submissions ADD COLUMN descriptor MEDIUMTEXT'
  end

  def self.down
    drop_table :app_submissions
  end
end
