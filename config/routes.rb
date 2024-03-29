BtWeb::Application.routes.draw do


  match 'stories/:id/legacy'  => 'admin/stories#legacyxml', :via=> [:get, :post]
  match 'stories/:id/clones'  => 'admin/stories#clonesxml', :via=> [:get, :post]

  namespace :api do

    post "/app_purchase" => "bright_text_applications#set_app_purchase", :defaults => { :format => 'json' }
    post "/is_paid_user" => "users#is_paid_user", :defaults => { :format => 'json' }
    post "/register_user" => "users#register_user", :defaults => { :format => 'json' }

    #apology wiz Endpoints
    post "/user_stories" => "apologies#get_user_stories"
    post "/user_app_stories" => "apologies#get_user_application_stories"
    post "/user_private_stories" => "apologies#get_user_private_stories"
    post "/app_public_stories" => "apologies#get_application_public_stories"

    #Word slider Endpoints
    post "/user_wordsliders" => "wordsliders#get_wordsliders_list"
    post "/get_public_wordsliders" => "wordsliders#get_public_wordsliders_list"
    
    #Scripture Words Endpoints
    post "/user_scriptwords" => "scriptwords#get_scriptwords_list"

    #Relax Texts Endpoints
    post "/user_relexts" => "relexts#get_relexts_list"
    
  end

  namespace :admin do
    resources :app_submissions
    resources :domain_styles
    resources :password_resets
    resources :stories
    resource :session, only: [:new, :create, :destroy]

    #match 'stories/:id' => 'stories#destroy', :via => :delete
    post '/upload' => 'stories#upload', as: :upload
    get '/import' => 'stories#import', as: :import
    post '/users/authenticate' => 'users#authenticate'
    get '/login' => 'users#new_session', as: :login
    get '/logout' => 'users#destroy_session', as: :logout
    root to: "users#new_session"

    #match 'proxy/:id/story'   => 'bt_proxy#story'  , :as => :story
    #match 'proxy/:id/related' => 'bt_proxy#related', :as => :story
    #match 'story/save'        => 'bt_proxy#save'
    #match 'stories/:id/clone'  => 'stories#clone', :via=> [:get, :post]
    #match 'stories/:id/delete' => 'stories#destroy', :via=> [:get, :post]
    # match 'story/:id' => 'stories#destroy', :via => :delete, :as => :story_destroy

    #match 'stories/:id/legacy'  => 'stories#legacyxml', :via=> [:get, :post]
    #match 'stories/:id/clones'  => 'stories#clonesxml', :via=> [:get, :post]

    #match 'applications/:id/submitxml'  => 'app_submissions#submit', :via=> [:get, :post]
    #match 'applications/:id/results'  => 'bright_text_applications#result', :via=> [:get, :post]



    resources :domains

    get "/stories/reorder_stories_rank/:story_set_id" => "stories#reorder_stories_rank", :as => :reorder_stories_rank
    resources :stories do
      member do
        get :clone
        get :publish
      end
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
    get "/story_set_categories/:id/story_sets" => "story_set_categories#category_story_sets", :as => :category_story_sets, :format => :json
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


  namespace :apologywiz do

    resources :password_resets
    resources :users
    resources :groups
    resources :group_members

    post '/users/authenticate' => 'users#authenticate'
    get '/login' => 'users#new_session', as: :login
    get '/register' => 'users#new', as: :register
    get '/logout' => 'users#destroy_session', as: :logout
    root to: "users#new_session"
    
    resources :stories
    match 'stories/:id' => 'stories#update', :via=> [:get, :post]
    match 'proxy/:id/story'   => 'bt_proxy#story', :via=> [:get, :post]
    match 'proxy/:id/related' => 'bt_proxy#related', :via=> [:get, :post]
    match 'story/save'        => 'bt_proxy#save', :via=> [:get, :post]
    match 'stories/:id/clone'  => 'stories#clone', :via=> [:get, :post]
    match 'stories/:id/delete' => 'stories#destroy', :via=> [:get, :post]
    # match 'story/:id' => 'stories#destroy', :via => :delete, :as => :story_destroy

    match 'stories/:id/legacy'  => 'stories#legacyxml', :via=> [:get, :post]
    match 'stories/:id/clones'  => 'stories#clonesxml', :via=> [:get, :post]

    match 'applications/:id/submitxml'  => 'app_submissions#submit', :via=> [:get, :post]
    match 'applications/:id/results'  => 'bright_text_applications#result', :via=> [:get, :post]


    match "/session/:id" => "session#create", :via=> [:get, :post]

    match "/login" => "session#new", :via => :get
    match "/logout" => "session#destroy", :via => :get

    
  end
  
  namespace :wordslider do
    resources :password_resets
    resources :users
    resources :groups
    resources :group_members

    post '/users/authenticate' => 'users#authenticate'
    get '/login' => 'users#new_session', as: :login
    get '/register' => 'users#new', as: :register
    get '/logout' => 'users#destroy_session', as: :logout
    root to: "users#new_session"
    
    resources :stories
    match 'stories/:id' => 'stories#update', :via=> [:get, :post]
    match 'proxy/:id/story'   => 'bt_proxy#story', :via=> [:get, :post]
    match 'proxy/:id/related' => 'bt_proxy#related', :via=> [:get, :post]
    match 'story/save'        => 'bt_proxy#save', :via=> [:get, :post]
    match 'stories/:id/clone'  => 'stories#clone', :via=> [:get, :post]
    match 'stories/:id/delete' => 'stories#destroy', :via=> [:get, :post]
    # match 'story/:id' => 'stories#destroy', :via => :delete, :as => :story_destroy

    match 'stories/:id/legacy'  => 'stories#legacyxml', :via=> [:get, :post]
    match 'stories/:id/clones'  => 'stories#clonesxml', :via=> [:get, :post]

    match 'applications/:id/submitxml'  => 'app_submissions#submit', :via=> [:get, :post]
    match 'applications/:id/results'  => 'bright_text_applications#result', :via=> [:get, :post]


    match "/session/:id" => "session#create", :via=> [:get, :post]

    match "/login" => "session#new", :via => :get
    match "/logout" => "session#destroy", :via => :get

  end
   
  namespace :scriptwords do
    resources :password_resets
    resources :users
    resources :groups
    resources :group_members

    post '/users/authenticate' => 'users#authenticate'
    get '/login' => 'users#new_session', as: :login
    get '/register' => 'users#new', as: :register
    get '/logout' => 'users#destroy_session', as: :logout
    root to: "users#new_session"
    
    resources :stories
    match 'stories/:id' => 'stories#update', :via=> [:get, :post]
    match 'proxy/:id/story'   => 'bt_proxy#story', :via=> [:get, :post]
    match 'proxy/:id/related' => 'bt_proxy#related', :via=> [:get, :post]
    match 'story/save'        => 'bt_proxy#save', :via=> [:get, :post]
    match 'stories/:id/clone'  => 'stories#clone', :via=> [:get, :post]
    match 'stories/:id/delete' => 'stories#destroy', :via=> [:get, :post]
    # match 'story/:id' => 'stories#destroy', :via => :delete, :as => :story_destroy

    match 'stories/:id/legacy'  => 'stories#legacyxml', :via=> [:get, :post]
    match 'stories/:id/clones'  => 'stories#clonesxml', :via=> [:get, :post]

    match 'applications/:id/submitxml'  => 'app_submissions#submit', :via=> [:get, :post]
    match 'applications/:id/results'  => 'bright_text_applications#result', :via=> [:get, :post]


    match "/session/:id" => "session#create", :via=> [:get, :post]

    match "/login" => "session#new", :via => :get
    match "/logout" => "session#destroy", :via => :get

  end
   
  namespace :relext do
    resources :password_resets
    resources :users
    resources :groups
    resources :group_members

    post '/users/authenticate' => 'users#authenticate'
    get '/login' => 'users#new_session', as: :login
    get '/register' => 'users#new', as: :register
    get '/logout' => 'users#destroy_session', as: :logout
    root to: "users#new_session"
    
    resources :stories
    match 'stories/:id' => 'stories#update', :via=> [:get, :post]
    match 'proxy/:id/story'   => 'bt_proxy#story', :via=> [:get, :post]
    match 'proxy/:id/related' => 'bt_proxy#related', :via=> [:get, :post]
    match 'story/save'        => 'bt_proxy#save', :via=> [:get, :post]
    match 'stories/:id/clone'  => 'stories#clone', :via=> [:get, :post]
    match 'stories/:id/delete' => 'stories#destroy', :via=> [:get, :post]
    # match 'story/:id' => 'stories#destroy', :via => :delete, :as => :story_destroy

    match 'stories/:id/legacy'  => 'stories#legacyxml', :via=> [:get, :post]
    match 'stories/:id/clones'  => 'stories#clonesxml', :via=> [:get, :post]

    match 'applications/:id/submitxml'  => 'app_submissions#submit', :via=> [:get, :post]
    match 'applications/:id/results'  => 'bright_text_applications#result', :via=> [:get, :post]


    match "/session/:id" => "session#create", :via=> [:get, :post]

    match "/login" => "session#new", :via => :get
    match "/logout" => "session#destroy", :via => :get
  end
  
end
