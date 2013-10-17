class ChangeDataTypeForStoriesDescription < ActiveRecord::Migration
  def self.up
      change_column :stories, :description, :string, :limit => 1024
  end

  def self.down
      change_column :stories, :description, :string, :limit => 255
  end
end
