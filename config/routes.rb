Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  # get "offline" => "rails/pwa#offline", as: :pwa_offline

  # Sign in with GitHub and nothing else.
  #
  # The request phase is POST only: omniauth-rails_csrf_protection checks the
  # authenticity token on it, which is what stops a third-party page from
  # silently signing a visitor into an account of its choosing. OmniAuth's
  # middleware intercepts this path before routing, so #passthru never runs.
  get  "sign-in", to: "sessions#new", as: :sign_in
  post "auth/github", to: "sessions#passthru", as: :github_auth
  get  "auth/github/callback", to: "sessions#create"
  get  "auth/failure", to: "sessions#failure"
  delete "session", to: "sessions#destroy", as: :session

  # The library is the home page.
  root "exercises#index"

  # Exercises are addressed by slug, never by id: the slug is the stable name an
  # exercise is authored under and the one a link can be shared with.
  resources :exercises, only: :show, param: :slug
end
