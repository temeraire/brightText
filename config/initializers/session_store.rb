# Be sure to restart your server when you modify this file.

#BtWeb::Application.config.session_store  :cookie_store, key: '_btWeb_session'
#BtWeb::Application.config.session_store  :active_record_store
#ActiveRecord::SessionStore::Session.attr_accessible :data, :session_id
BtWeb::Application.config.session_store  :redis_store

