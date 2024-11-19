require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  # Devise routes for accounts
  devise_for :accounts, controllers: {
    sessions: "accounts/sessions",
    registrations: "accounts/registrations",
    passwords: "accounts/passwords"
  }

  devise_scope :account do
    patch "update_account/:id", to: "pages#update_account", as: :update_account
    delete "logout", to: "pages#logout", as: :logout
    delete "adminlogout", to: "adminhomes#adminlogout", as: :adminlogout
  end

  # Static pages
  get "aboutus", to: "pages#aboutus", as: :about_us
  get "noindex", to: "adminhomes#noindex", as: :noindex
  get "userhome", to: "pages#userhome", as: :users_home
  get "producthome", to: "products#index", as: :products_index
  get "typehome", to: "categories#index", as: :categories_index
  get "accounthome", to: "accounts#index", as: :accounts_index
  get "myaccount", to: "pages#myaccount", as: :my_account
  get "shop_cart", to: "pages#shop_cart", as: :shop_cart
  get "delivery_form", to: "pages#delivery_form", as: :delivery_form
  post 'update_delivery', to: 'pages#update_delivery', as: :update_delivery
  get "shop", to: "pages#shop", as: :shop

  # Delivery history and account management
  get "account_management", to: "pages#account_management", defaults: { format: "js" }
  get "delivery_history", to: "pages#delivery_history", defaults: { format: "js" }

  # Promotions
  get "promotions/new"
  get "promotions/create"
  post "apply_promotion", to: "promotions#apply"

  # Products export report
  post "products/export_report", to: "products#export_report", as: :export_report

  # Admin home
  get "adminhome", to: "adminhomes#index", as: :adminhomes_index
  get "adminhomes/category_totals", to: "adminhomes#category_totals"

  # Resources
  resources :merchandises, only: [:index, :create, :destroy]
  resources :products, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    collection do
      post "import"  # Add this line to include the import action
      get :render_product_datatable
      get :render_merchandise_datatable
      get :render_promotion_datatable
    end
  end
  resources :accounts, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    collection do
      post "import"  # Import action already present
      get "render_account_datatable", to: "accounts#render_account_datatable", as: :render_account_datatable  # Correctly define the route
    end
  end
  resources :categories, only: [:index, :create, :destroy] do
    collection do
      post "refreshtotal"
      post :import
    end
  end

  resources :adminhomes, only: [:index] do
    collection do
      post 'export_report'
    end
  end

  resources :cart_items, only: [:create, :update, :destroy] do
    collection do
      post "apply_promotion"
    end
  end
  resources :promotions, only: [:new, :create, :destroy, :index] do
    collection do
      post "check_type"
    end
  end
  resources :carts, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
    collection do
      get "render_cart_datatable", to: "carts#render_cart_datatable", as: :render_cart_datatable
    end
    member do
      patch "checkout"
      post "apply_cart_promotion"
      patch "update_item"
    end
  end
end
