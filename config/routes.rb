Rails.application.routes.draw do
  mount GoodJob::Engine => "/admin/jobs"

  resource :session
  resources :passwords, param: :token

  get "healthz" => "rails/health#show", :as => :rails_health_check

  # for backwards compat until we get the user(s) migrated
  get "/pub/peers/all", to: "exports#all", as: :all_endpoints_export
  get "/pub/peers/ips", to: "exports#ips", as: :ip_endpoints_export

  get "/export/:user_slug/peers/:variant", to: "exports#peers", as: :export_peerlist

  # DynDNS2 protocol https://help.dyn.com/perform-update.html
  get "/nic/update", to: "ddns#update", as: :ddns_update

  resources :endpoints do
    patch :disable, on: :member
    patch :enable, on: :member
  end

  resources :exports, only: [:index]
  resources :external_zones, only: [:index]

  get :onboarding, to: "onboarding#index"
  post :onboarding, to: "onboarding#create"

  resources :signups, only: [:new, :create], param: :token do
    get :confirm, on: :member
  end

  resources :users, except: [:new, :create, :destroy], path: "members"

  get "/u/:name", to: "users#show_by_name", as: :user_by_name, format: false, constraints: {name: /[^\/]+/}
  get "/z/:name", to: "zones#show_by_name", as: :zone_by_name, format: false, constraints: {name: /[^\/]+/}

  resources :zones

  root "home#index"

  match "*unmatched", to: "errors#not_found", via: :all
end
