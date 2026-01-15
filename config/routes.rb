Rails.application.routes.draw do
  root "home#index"
  get "home/index"

  get  "signup", to: "registrations#new", as: :signup
  post "signup", to: "registrations#create"

  resource :session, only: [ :create, :destroy ]
  get "login", to: "sessions#new"
  delete "logout", to: "sessions#destroy"

  resources :passwords, param: :token

  resources :products, only: [ :show, :new, :create ] do
    resources :price_alerts, only: [ :create, :edit ]
  end

  resources :price_alerts, only: [ :index, :create, :update, :destroy ] do
    member do
      patch :toggle
    end
  end

  get "/health", to: "health#show"
end
