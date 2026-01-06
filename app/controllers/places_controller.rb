class PlacesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_place, only: [:show]

  def index
    @places = current_user.places.roots.order(:id)
  end

  def show
    @children = @place.children.order(:id)
    @items = @place.items.order(:id)
  end

  def new
    @parent = current_user.places.find_by(id: params[:parent_id])
    @place = current_user.places.new
  end

  def create
    @place = current_user.places.new(place_params)

    if params[:parent_id].present?
      parent = current_user.places.find(params[:parent_id])
      @place.parent = parent
    end

    if @place.save
      redirect_to place_path(@place), notice: "Placeを作成しました"
    else
      @parent = current_user.places.find_by(id: params[:parent_id])
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_place
    @place = current_user.places.find(params[:id])
  end

  def place_params
    params.require(:place).permit(:name, :description)
  end
end
