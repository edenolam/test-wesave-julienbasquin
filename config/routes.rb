Rails.application.routes.draw do
  root to: redirect("/docs/index.html")
  get "/docs", to: redirect("/docs/index.html")
  get "up" => "rails/health#show", as: :rails_health_check
  namespace :api do
    namespace :v1 do
      resources :users, only: :create
      resource :session, only: %i[create destroy]
      resources :assets, only: :index do
        get :prices, on: :member
      end
      resources :portfolios, only: %i[index show create] do
        member do
          get :positions
          get :valuation
        end
        resources :trades, only: %i[index create]
      end
    end
  end
end
