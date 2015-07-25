# Be sure to restart your server when you modify this file.

#BtWeb::Application.config.session_store  :cookie_store, key: '_btWeb_session'
<<<<<<< HEAD
#BtWeb::Application.config.session_store  :active_record_store
#ActiveRecord::SessionStore::Session.attr_accessible :data, :session_id
BtWeb::Application.config.session_store  :redis_store

=======
BtWeb::Application.config.session_store  :redis_store
#ActiveRecord::SessionStore::Session.attr_accessible :data, :session_id
>>>>>>> dd7bb76469f789e3cac858a66a4837e9d00cf8b8
