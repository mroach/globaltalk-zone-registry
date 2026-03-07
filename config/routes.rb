Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "healthz" => "rails/health#show", :as => :rails_health_check

  resources :exports, only: [:index]
  get "/pub/exports/endpoints.txt", to: "exports#endpoints", as: :endpoints_export

  # DynDNS2 protocol https://help.dyn.com/perform-update.html
  get "/nic/update", to: "ddns#update", as: :ddns_update

  resources :signups, only: [:new, :create], param: :token do
    get :confirm, on: :member
  end

  resources :zones do
    patch :approve, on: :member
    patch :reject, on: :member
    patch :disable, on: :member
    patch :enable, on: :member
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
