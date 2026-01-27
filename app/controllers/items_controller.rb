class ItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_place_from_nested, only: [:new, :create, :destroy], if: -> { params[:place_id].present? }

  before_action :set_item, only: [:edit, :update]
  before_action :set_places_for_select, only: [:edit]

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
  end

  def update
    if @item.update(item_params)
      redirect_to root_path(place_id: @item.place_id, item_id: @item.id), notice: 'Itemを更新しました'
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
      respond_to do |format|
        format.html do
          redirect_to root_path(place_id: place.id, item_id: @item.id), notice: 'Itemを追加しました'
        end

        format.turbo_stream do
          prepare_turbo_stream_state(place: place, selected_item: @item)
          render turbo_stream: turbo_stream_updates(include_left_quick: true)
        end
      end
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
      respond_to do |format|
        format.html do
          redirect_to root_path(place_id: place.id, item_id: @item.id), notice: '未分類に追加しました'
        end

        format.turbo_stream do
          prepare_turbo_stream_state(place: place, selected_item: @item)
          render turbo_stream: turbo_stream_updates(include_left_quick: true)
        end
      end
    else
      # エラーもトップに戻して出す（places_path だと別画面になるため）
      redirect_to root_path(place_id: place.id), alert: @item.errors.full_messages.to_sentence
    end
  end

  def destroy
    @item = @place.items.find(params[:id])

    if @item.destroy
      respond_to do |format|
        format.html do
          redirect_to root_path(place_id: @place.id), notice: 'Itemを削除しました'
        end

        format.turbo_stream do
          prepare_turbo_stream_state(place: @place, selected_item: nil)
          render turbo_stream: turbo_stream_updates
        end
      end
    else
      respond_to do |format|
        format.html do
          redirect_to root_path(place_id: @place.id), alert: @item.errors.full_messages.to_sentence
        end

        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash", partial: 'shared/flash', locals: { alert: @item.errors.full_messages.to_sentence })
        end
      end
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

  def prepare_turbo_stream_state(place:, selected_item:)
    @current_place = place
    @base_items = @current_place ? @current_place.items : Item.none
    @q = nil
    @items = @base_items.order(:name)
    @selected_item = selected_item
  end

  def turbo_stream_updates(include_left_quick: false)
    streams = [
      turbo_stream.update(
        'place_tree',
        partial: 'places/place_tree',
        locals: { place_tree: current_user.places.arrange(order: :name), current_place: @current_place }
      ),
      turbo_stream.update(
        'middle_pane',
        partial: 'places/middle_pane'
      ),
      turbo_stream.update(
        'right_pane',
        partial: 'places/right_pane',
        locals: { current_place: @current_place, selected_item: @selected_item }
      )
    ]

    if include_left_quick
      streams.insert(
        1,
        turbo_stream.update(
          'left_quick',
          partial: 'places/left_quick'
        )
      )
    end

    streams
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
