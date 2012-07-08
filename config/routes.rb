BrightText::Application.routes.draw do


  resources :users

  match 'proxy/:id/story'   => 'bt_proxy#story'  , :as => :story
  match 'proxy/:id/related' => 'bt_proxy#related', :as => :story
  match 'story/save'        => 'bt_proxy#save'
  match 'stories/:id/clone'  => 'stories#clone'
  
  match 'stories/:id/legacy'  => 'stories#legacyxml'
  match 'stories/:id/clones'  => 'stories#clonesxml'
  
  
  
  
  match "/session/:id" => "session#create"   
  

  resources :domains
  resources :stories 
  resources :story_sets
  resources :story_set_categories
  resources :bright_text_applications
  
end
