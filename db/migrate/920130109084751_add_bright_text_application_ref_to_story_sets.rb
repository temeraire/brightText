class AddBrightTextApplicationRefToStorySets < ActiveRecord::Migration
  def change
    add_reference :story_sets, :bright_text_application, index: true
  end
end
