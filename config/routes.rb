Rails.application.routes.draw do
  devise_for :users

  root "places#index"

  get 'profile', to: 'users#show', as: :profile

  resources :places, only: [:index, :show, :new, :create, :destroy] do
    resources :items, only: [:new, :create, :destroy]
  end

  resources :items, only: [:new, :create] do
    collection do
      post :quick_create
    end
  end
end
