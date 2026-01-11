class ItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_place_from_nested, only: [:new, :create, :destroy], if: -> { params[:place_id].present? }

  def new
    @item = current_user.items.new

    if @place.present?
      @item.place = @place
    else
      set_places_for_select
      @item.place = current_user.unclassified_place
    end
  end

  def create
    place = resolve_place_for_create!

    @item = current_user.items.new(item_params.except(:place_id))
    @item.place = place

    if @item.save
      redirect_to place_path(place), notice: "Itemを追加しました"
    else
      if params[:place_id].blank?
        set_places_for_select
      else
        @place = place
      end
      render :new, status: :unprocessable_entity
    end
  end

  def quick_create
    place = current_user.unclassified_place
    @item = current_user.items.new(quick_item_params)
    @item.place = place

    if @item.save
      redirect_to place_path(place), notice: "未分類に追加しました"
    else
      redirect_to places_path, alert: @item.errors.full_messages.to_sentence
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

  def set_place_from_nested
    @place = current_user.places.find(params[:place_id])
  end

  def set_places_for_select
    @places = current_user.places.order(:name)
  end

  def resolve_place_for_create!
    if params[:place_id].present?
      @place
    elsif item_params[:place_id].present?
      current_user.places.find(item_params[:place_id])
    else
      current_user.unclassified_place
    end
  end

  def item_params
    params.require(:item).permit(:name, :quantity, :note, :status, :place_id)
  end

  def quick_item_params
    params.require(:item).permit(:name, :quantity, :note, :status)
  end
end
