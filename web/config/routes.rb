Web::Application.routes.draw do
  resources :trees
  resources :advs
  get "home/index"
  match "/cat/:id" => "home#index" 
  root :to => "home#index"
end
