class AddBrightTextApplicationRefToUsers < ActiveRecord::Migration
  def change
    add_reference :users, :bright_text_application, index: true
  end
end
