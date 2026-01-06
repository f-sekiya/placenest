Rails.application.routes.draw do
  devise_for :users

  root "places#index"

  resources :places, only: [:index, :show, :new, :create] do
    resources :items, only: [:new, :create]
  end
end
