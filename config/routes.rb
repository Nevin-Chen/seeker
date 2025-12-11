Rails.application.routes.draw do
  root "home#index"
  get "home/index"

  get "registrations/new"
  get "registrations/create"
  resource :session
  resources :passwords, param: :token

  get  "signup", to: "registrations#new", as: :signup
  post "signup", to: "registrations#create"
end
