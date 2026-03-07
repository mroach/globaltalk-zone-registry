Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  get "healthz" => "rails/health#show", :as => :rails_health_check

  get "/pub/exports/endpoints.txt", to: "exports#endpoints", as: :endpoints_export

  # DynDNS2 protocol https://help.dyn.com/perform-update.html
  get "/nic/update", to: "ddns#update", as: :ddns_update

  resources :exports, only: [:index]


  resources :signups, only: [:new, :create], param: :token do
    get :confirm, on: :member
  end

  resources :users, except: [:new, :create, :destroy]

  resources :zones do
    patch :approve, on: :member
    patch :reject, on: :member
    patch :disable, on: :member
    patch :enable, on: :member
  end

  root "home#index"
end
