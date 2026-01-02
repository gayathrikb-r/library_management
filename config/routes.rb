Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  get "auth/login"
  # Member namespace
  namespace :member do
    get "dashboard/show", to: "dashboard#show", as: :dashboard
  end
  namespace :librarians do
    get "dashboard", to: "dashboard#index", as: :dashboard
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
  }, skip: [:registrations] # prevent librarians from signing up

  # Books, authors, categories
  resources :books do
    member do
      post :borrow
      post :reserve
    end
    resources :reviews, only: [:create]
  end

  resources :authors do
    resources :reviews, only: [:create]
  end

  resources :categories

  # Borrowings & Reservations
  resources :borrowings, only: [:index, :show, :create] do
    member { patch :return_book }
  end

  resources :reservations, only: [:index, :show, :create] do
    member { patch :cancel }
  end
  resources :members, only: [:show,:edit,:update]

  # Reviews actions
  resources :reviews, only: [:edit, :update, :destroy] do
    member do
      patch :flag     # members
      patch :approve  # librarians
    end
  end

  ActiveAdmin.routes(self)
end
