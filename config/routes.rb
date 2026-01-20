Rails.application.routes.draw do
  use_doorkeeper
  devise_for :admin_users, ActiveAdmin::Devise.config

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

  devise_for :members, 
    path: "members", 
    path_names: { sign_up: '../sign_up' }, 
    controllers: {
      registrations: "members/registrations",
      sessions: "members/sessions",
      passwords: "members/passwords"
    }

  devise_scope :member do
    get "/sign_up", to: "members/registrations#new"
    post "/sign_up", to: "members/registrations#create"
  end

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
    collection do
      get :popular
      get :highest_rated
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

  resources :members, only: [:show, :edit, :update] do
    member do
      get :activity
    end
  end

  # Reviews actions
  resources :reviews, only: [:edit, :update, :destroy] do
    member do
      patch :flag     # members
      patch :approve  # librarians
    end
  end

  # Reservations actions 
  namespace :librarians do
    resources :reservations, only: [:index] do
      member do
        patch :fulfill
        patch :cancel
      end
    end
    resources :reviews, only: [:index, :show] do
    member do
      patch :approve
    end
  end
  end

  # Api
  namespace :api do
    namespace :v1 do
      # Books, authors, categories
      resources :books do
        member do
          post :borrow
          post :reserve
        end
        collection do
          get :popular
          get :highest_rated
        end
        resources :reviews, only: [:create]
      end

      resources :authors do
        resources :reviews, only: [:create]
      end

      resources :categories


      resources :borrowings, only: [:index, :show, :create] do
        member { patch :return_book }
      end

      resources :reservations, only: [:index, :show, :create] do
        member { patch :cancel }
      end

      resources :members, only: [:show, :edit, :update] do
        member do
          get :activity
        end
      end

      # Reviews actions
      resources :reviews, only: [:edit, :update, :destroy] do
        member do
          patch :flag     # members
          patch :approve  # librarians
        end
      end

      namespace :member do
        get "dashboard/show", to: "dashboard#show", as: :dashboard
      end

      namespace :librarians do
        get "dashboard", to: "dashboard#index"
        
        resources :reservations, only: [:index] do
          member do
            patch :fulfill
            patch :cancel
          end
        end
      
        resources :reviews, only: [:index, :show] do
          member do
            patch :approve
          end
        end
      end
    end
  end

  ActiveAdmin.routes(self)
end