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


    admin    = Domain.create( :name_first => 'David', :name_last => 'Wolpe', :nickname=> 'Admin', :email => "wolped@gmail.com", :password => "test", :password_confirmation => "test", :owner_domain_id => nil, :enabled => true, :priveleged => true, :self_created => false )
    context  = Domain.create( :name_first => 'Asif', :name_last => 'Tasleem', :nickname=> 'ContextIT', :email => "asiftasleem@gmail.com", :password => "test", :password_confirmation => "test", :owner_domain_id => 1, :enabled => true, :priveleged => true, :self_created => false )

    admin.save
    context.save
  end

  def self.down
    drop_table :domains
  end
end
