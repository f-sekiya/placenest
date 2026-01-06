class ItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_place

  def new
    @item = current_user.items.new
    @item.place = @place
  end

  def create
    @item = current_user.items.new(item_params)
    @item.place = @place

    if @item.save
      redirect_to place_path(@place), notice: "Itemを追加しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @item = @place.items.find(params[:id])
    if @item.destroy
      redirect_to place_path(@place), notice: "Itemを削除しました"
    else
      redirect_to place_path(@place), alert: @item.errors.full_messages.to_sentence
    end
  end

  private

  def set_place
    @place = current_user.places.find(params[:place_id])
  end

  def item_params
    params.require(:item).permit(:name, :quantity, :note, :status)
  end
end
