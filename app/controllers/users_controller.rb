class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @places_count = @user.places.count
    @items_count = @user.items.count
  end
end
