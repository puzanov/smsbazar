Web::Application.routes.draw do
  resources :trees
  resources :advs
  get "home/index"
  match "/cat/:id" => "home#index" 
  match "/add_category" => "home#add_category" 
  root :to => "home#index"
end
