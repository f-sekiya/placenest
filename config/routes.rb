Rails.application.routes.draw do
  devise_for :users

  root "places#index"

  resources :places, only: [:index, :show, :new, :create, :destroy] do
    resources :items, only: [:new, :create, :destroy]
  end
end
