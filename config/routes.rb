Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "books#index"

  get "/signup", to: "users#new"
  post "/signup", to: "users#create"

  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  resources :users do
    member { get :dashboard }
  end

  resources :books do
    member do
      post :borrow
      post :reserve
    end
    resources :reviews, only: [:create, :edit, :update, :destroy]
  end

  resources :authors do
    resources :reviews, only: [:create, :edit, :update, :destroy]
  end

  resources :categories

  resources :borrowings, only: [:index, :show, :create] do
    member { patch :return_book }
  end

  resources :reservations, only: [:index, :show, :create] do
    member { patch :cancel }
  end

  resources :reviews, only: [] do
    member { patch :flag }
  end

  namespace :librarian do
    get "dashboard/index"
    root to: "dashboard#index"

    resources :users
    resources :borrowings
    resources :reservations
    resources :reviews do
      member { patch :approve }
    end
  end
end
