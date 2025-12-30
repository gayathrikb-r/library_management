Rails.application.routes.draw do
  get "auth/login"
  # Member namespace
  namespace :member do
    get "dashboard/show", to: "dashboard#show", as: :dashboard
  end

  # Health check & PWA
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Root
  root "books#index"

  get "/login", to: "auth#login", as: :login
  get "/sign_up", to: "auth#signup"
  # Devise routes
  devise_for :members, path: "members", controllers: {
    registrations: "members/registrations",
    sessions: "members/sessions"
  }

  devise_for :librarians, path: "librarians", controllers: {
    registrations: "librarians/registrations",
    sessions: "librarians/sessions"
  }

  # Books, authors, categories
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

  # Borrowings & Reservations
  resources :borrowings, only: [:index, :show, :create] do
    member { patch :return_book }
  end

  resources :reservations, only: [:index, :show, :create] do
    member { patch :cancel }
  end

  # Reviews actions
  resources :reviews, only: [] do
    member { patch :flag }
  end

  # Admin namespace handled by ActiveAdmin
  namespace :admin do
    root to: "dashboard#index" # ActiveAdmin default dashboard
    # ActiveAdmin resources (will be registered in app/admin/*)
  end
end
