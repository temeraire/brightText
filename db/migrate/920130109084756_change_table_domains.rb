class ChangeTableDomains < ActiveRecord::Migration
  def change
    remove_column :domains, :name_first
    remove_column :domains, :name_last
    remove_column :domains, :pass    
    remove_column :domains, :password_confirmation
    remove_column :domains, :salt
    rename_column :domains, :nickname, :name
    rename_column :domains, :priveleged, :privileged
    
    

  end
end
