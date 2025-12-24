Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"
  root "books#index"
  get "/signup", to: "users#new"
  post "/signup", to: "users#create"
  get "/login", to: "sessions#new"
  post '/login',  to: 'sessions#create'
  delete '/logout', to: "sessions#destroy"
  #Current user profile
  resource :profile, only: [:show, :edit, :update]
  #Public resources
  resources :users do
    member {get :dashboard}
  end
  resources :books do
    member do
      post :borrow
      post :reserve
    end
    resources :reviews, only: [:create,:edit,:update,:destroy]
  end
  resources :authors do
    resources :reviews, only: [:create,:edit,:update,:destroy]
  end
  resources :categories
  resources :borrowings, only: [:index,:show,:create] do
    member {patch :return_book}
  end
  resources :reservations, only: [:index, :show, :create] do
    member {patch :cancel}
  end
  #public review action to be flagged
  resources :reviews, only: [] do
    member {patch :flag}
  end
  namespace :librarian do
    get "dashboard/index"
    root to: "dashboard#index"
    resources :users
    resources :borrowings
    resources :reservations
    resources :reviews do
      member {patch :approve}
    end
  end
end
