class CreateDomains < ActiveRecord::Migration
  def self.up
    create_table :domains do |t|
      t.string   :name_first
      t.string   :name_last
      t.string   :email
      t.string   :pass
      t.string   :password_confirmation
      t.string   :salt
      t.string   :nickname
      t.integer  :owner_domain_id
      t.boolean  :enabled
      t.boolean  :priveleged 
      t.boolean  :self_created
      t.string   :role
      t.timestamps
    end
  end

  def self.down
    drop_table :domains
  end
end
