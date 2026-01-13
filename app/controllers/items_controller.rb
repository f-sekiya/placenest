class ItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_place_from_nested, only: [:new, :create, :edit, :update, :destroy], if: -> { params[:place_id].present? }

  before_action :set_item, only: [:edit, :update]

  def new
    @item = current_user.items.new

    if @place.present?
      @item.place = @place
    else
      set_places_for_select
      @item.place = current_user.unclassified_place
    end
  end

  def edit
    @item = current_user.items.find(params[:id])
    # 編集時は常に場所選択肢を用意する（場所の移動を許可）
    set_places_for_select
  end

  def update
    @item = current_user.items.find(params[:id])

    if @item.update(item_params)
      redirect_to root_path(place_id: @item.place_id, item_id: @item.id), notice: "Itemを更新しました"
    else
      # 編集失敗時も場所選択肢を用意して戻す
      set_places_for_select
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    place = resolve_place_for_create!

    @item = current_user.items.new(item_params.except(:place_id))
    @item.place = place

    if @item.save
      # トップ(Explorer)へ戻す。作成したItemを右ペイン選択にしたいなら item_id も渡す
      redirect_to root_path(place_id: place.id, item_id: @item.id), notice: "Itemを追加しました"
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
      redirect_to root_path(place_id: place.id, item_id: @item.id), notice: "未分類に追加しました"
    else
      # エラーもトップに戻して出す（places_path だと別画面になるため）
      redirect_to root_path(place_id: place.id), alert: @item.errors.full_messages.to_sentence
    end
  end

  def destroy
    @item = @place.items.find(params[:id])

    if @item.destroy
      # 削除後は item_id を付けない（消えたItemを選択しようとしない）
      redirect_to root_path(place_id: @place.id), notice: "Itemを削除しました"
    else
      redirect_to root_path(place_id: @place.id), alert: @item.errors.full_messages.to_sentence
    end
  end

  private

  def set_place_from_nested
    @place = current_user.places.find(params[:place_id])
  end

  def set_item
    @item = current_user.items.find(params[:id])
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
