Rails.application.routes.draw do
  devise_for :users

  root "places#index"

  get 'profile', to: 'users#show', as: :profile

  resources :places, only: [:index, :show, :new, :create, :destroy] do
    resources :items, only: [:new, :create, :destroy, :edit, :update]
  end

  resources :items, only: [:new, :create, :edit, :update] do
    collection do
      post :quick_create
    end
  end
end
