class AddBrightTextApplicationRefToStories < ActiveRecord::Migration
  def change
    add_reference :stories, :bright_text_application, index: true
  end
end
