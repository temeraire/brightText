BrightText::Application.routes.draw do

  namespace :admin do
    resources :app_submissions
    resources :domain_styles
    resources :password_resets
    resources :users
    resources :stories

    #match 'stories/:id' => 'stories#destroy', :via => :delete

    #root to: "stories#index"

    #match 'proxy/:id/story'   => 'bt_proxy#story'  , :as => :story
    #match 'proxy/:id/related' => 'bt_proxy#related', :as => :story
    #match 'story/save'        => 'bt_proxy#save'
    match 'stories/:id/clone'  => 'stories#clone'
    match 'stories/:id/delete' => 'stories#destroy'
    # match 'story/:id' => 'stories#destroy', :via => :delete, :as => :story_destroy

    match 'stories/:id/legacy'  => 'stories#legacyxml'
    match 'stories/:id/clones'  => 'stories#clonesxml'

    match 'applications/:id/submitxml'  => 'app_submissions#submit'
    match 'applications/:id/results'  => 'bright_text_applications#result'


    match "/session/:id" => "session#create", :via => :post   
    match "/login" => "session#new", :via => :get
    match "/logout" => "session#destroy", :via => :get

    resources :domains

    get "/stories/reorder_stories_rank/:story_set_id" => "stories#reorder_stories_rank", :as => :reorder_stories_rank
    resources :stories do
      collection do
        post :update_stories_rank
      end
    end

    get "/stories/reorder_story_sets_rank/:category_id" => "story_sets#reorder_story_sets_rank", :as => :reorder_story_sets_rank
    resources :story_sets do 
      member do
        get :clone
      end
      collection do
        post :update_story_sets_rank
      end
    end

    get "/story_set_categories/reorder_rank/:application_id" => "story_set_categories#reorder_story_set_categories_rank", :as => :reorder_story_set_categories_rank
    resources :story_set_categories do
      member do
        get :clone
      end
      collection do 
        post :update_story_set_categories_rank
      end
    end

    resources :bright_text_applications do
      member do 
        get :clone
      end
    end
  end
end
