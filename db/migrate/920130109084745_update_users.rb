class UpdateUsers < ActiveRecord::Migration
  def self.up
    change_table :users do |t|	
		t.string   :encrypted_password, :limit => 128, :default => "", :null => false
		t.string   :reset_password_token
		t.datetime :reset_password_sent_at
		t.datetime :remember_created_at
		t.integer  :sign_in_count, :default => 0
		t.datetime :current_sign_in_at
		t.datetime :last_sign_in_at
		t.string   :current_sign_in_ip
		t.string   :last_sign_in_ip
		t.index	   :email, :name => "index_users_on_email", :unique => true
		t.index	   :reset_password_token, :name => "index_users_on_reset_password_token", :unique => true
    end
  end

  def self.down
    change_table :users do |t|
	  t.remove_index :email
	  t.remove_index :reset_password_token
      t.remove :encrypted_password
      t.remove :reset_password_token
	  t.remove :reset_password_sent_at
	  t.remove :remember_created_at
	  t.remove :sign_in_count
	  t.remove :current_sign_in_at
	  t.remove :last_sign_in_at
	  t.remove :current_sign_in_ip
	  t.remove :last_sign_in_ip
    end
  end
end
