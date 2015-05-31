class AddBrightTextApplicationRefToGroupMembers < ActiveRecord::Migration
  def change
	add_reference :group_members, :bright_text_application, index: true
  end
end
