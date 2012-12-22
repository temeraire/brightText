BrightText::Application.routes.draw do


  resources :app_submissions

  resources :domain_styles

  resources :users

  match 'proxy/:id/story'   => 'bt_proxy#story'  , :as => :story
  match 'proxy/:id/related' => 'bt_proxy#related', :as => :story
  match 'story/save'        => 'bt_proxy#save'
  match 'stories/:id/clone'  => 'stories#clone'
  
  
  match 'stories/:id/legacy'  => 'stories#legacyxml'
  match 'stories/:id/clones'  => 'stories#clonesxml'
  
  match 'applications/:id/submitxml'  => 'app_submissions#submit'
  match 'applications/:id/results'  => 'bright_text_applications#result'
  
  
  match "/session/:id" => "session#create"   
  

  resources :domains
  
  get "/stories/reorder_stories_rank/:story_set_id" => "stories#reorder_stories_rank", :as => :reorder_stories_rank
  
  resources :stories do
    collection do
      post :update_stories_rank
    end
  end
  resources :story_sets
  resources :story_set_categories
  resources :bright_text_applications
  
end
