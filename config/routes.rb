Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "registrations" }
  authenticated :user do
    root 'users#dashboard', as: :authenticated_root
  end
  root to: 'pages#home'
  get "creation", to: "users#creation"
  get "dashboard", to: "users#dashboard"
  post "send_money", to: "users#send_money"
  get "choose_beneficiary", to: "users#choose_beneficiary"
  post "create_transfer", to: "users#create_transfer"
  get "add_beneficiary", to: "users#add_beneficiary"
  post "create_beneficiary", to: "users#create_beneficiary"
  get "sent_confirmation", to: "users#sent_confirmation"
  get "profile", to: "users#profile"
  get "account", to: "users#account"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
