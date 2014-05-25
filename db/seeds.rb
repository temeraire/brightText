# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)   
    
Domain.create( :nickname=> 'Admin', :email => "test@bar.com", :password => "test", :password_confirmation => "test", :owner_domain_id => nil, :enabled => true, :priveleged => true, :self_created => false )
Domain.create( :nickname=> 'ContextIT', :email => "test@foo.com", :password => "test", :password_confirmation => "test", :owner_domain_id => 1, :enabled => true, :priveleged => true, :self_created => false )
