Rails.application.routes.draw do
  devise_for :users
  root to: 'pages#home'
  authenticated :user do
    root 'users#dashboard', as: :authenticated_root
  end
  get "dashboard", to: "users#dashboard"
  get "send_money", to: "users#send_money"
  get "dashboard", to: "users#dashboard"
  post "create_transfer", to: "users#create_transfer"
  get "add_beneficiary", to: "users#add_beneficiary"
  post "create_beneficiary", to: "users#create_beneficiary"
  get "sent_confirmation", to: "users#sent_confirmation"
  get "account", to: "users#account"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
