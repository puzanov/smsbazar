Web::Application.routes.draw do
  resources :trees
  get "home/index"
  
  match "/cat/:id" => "home#index" 
  match "/add_category" => "home#add_category" 
  match "/delete_category/:id" => "home#delete_category" 
  match "/edit_category/:id" => "home#edit_category" 
  match "/add_adv" => "home#add_adv"
  
  root :to => "home#index"

  match "/advs" => "advs#index"
  match "/advs/delete/:id" => "advs#delete"

  match "/help" => "help#index"
end
