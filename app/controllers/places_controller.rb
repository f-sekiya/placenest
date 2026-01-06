class PlacesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_place, only: [:show, :destroy]

  def index
    @places = current_user.places.roots.order(:id)
  end

  def show
    @children = @place.children.order(:id)
    @items = @place.items.order(:id)
  end

  def destroy
    begin
      if @place.destroy
        redirect_to places_path, notice: "Placeを削除しました"
      else
        redirect_to place_path(@place), alert: @place.errors.full_messages.to_sentence
      end
    rescue Ancestry::AncestryException => e
      redirect_to place_path(@place), alert: e.message
    end
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
