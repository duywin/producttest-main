Rails.application.routes.draw do
  get 'promotions/new'
  get 'promotions/create'
  get 'pages/userhome'
  devise_for :accounts, controllers: {
    sessions: "accounts/sessions",
    registrations: 'accounts/registrations',
    passwords: 'accounts/passwords'
  }

  devise_scope :account do
    patch 'update_account/:id', to: 'pages#update_account', as: :update_account
    delete 'logout', to: 'pages#logout', as: :logout
    delete 'adminlogout', to: 'adminhomes#adminlogout', as: :adminlogout
  end

  get 'noindex', to: 'adminhomes#noindex', as: :noindex
  get 'adminhome', to: 'adminhomes#index', as: :adminhomes_index
  get 'adminhomes/category_totals', to: 'adminhomes#category_totals'
  get 'producthome', to: 'products#index', as: :products_index
  get 'aboutus', to: 'pages#aboutus', as: :about_us
  get 'userhome', to: 'pages#userhome', as: :users_home
  get 'typehome', to: 'categories#index', as: :categories_index
  get 'accounthome', to: 'accounts#index', as: :accounts_index

  get 'myaccount', to: 'pages#myaccount', as: :my_account
  get 'shop_cart', to: 'pages#shop_cart', as: :shop_cart
  get 'delivery_form', to: 'pages#delivery_form', as: :delivery_form
  post 'update_delivery', to: 'pages#update_delivery', as: :update_delivery
  get 'shop', to: 'pages#shop', as: :shop
  get 'account_management', to: 'pages#account_management', defaults: { format: 'js' }
  get 'delivery_history', to: 'pages#delivery_history', defaults: { format: 'js' }

  post 'apply_promotion', to: 'promotions#apply'
  post 'products/export_report', to: 'products#export_report', as: :export_report



  # Resources
  resources :merchandises, only: [:index, :create, :destroy]
  resources :products, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  resources :accounts, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  resources :categories, only: [:index, :create, :destroy]
  resources :adminhomes, only: [:index]
  resources :cart_items, only: [:create, :update, :destroy] do
    collection do
      post 'apply_promotion'
    end
  end
  resources :promotions, only: [:new, :create, :destroy, :index] do
  collection do
    post 'check_type'
  end
end
  resources :categories do
    collection do
      post 'refreshtotal'
      post :import
    end
  end
  resources :products do
    collection do
      post 'import'  # Add this line to include the import action
    end
  end
  resources :accounts do
    collection do
      post 'import'  # Add this line to include the import action
    end
  end
  resources :carts, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
    member do
      patch 'checkout'
      post 'apply_cart_promotion'
      patch 'update_item'
    end
  end

end


