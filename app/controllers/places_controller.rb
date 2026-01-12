class PlacesController < ApplicationController
  layout "explorer", only: [:index]
  before_action :authenticate_user!
  before_action :set_place, only: [:show, :destroy]

  def index
    # 左ツリー（階層表示用）
    @place_tree = current_user.places.arrange(order: :name)

    # 現在地（place_id が無ければ未分類）
    @current_place =
      if params[:place_id].present?
        current_user.places.find_by(id: params[:place_id])
      else
        current_user.unclassified_place
      end
    @current_place ||= current_user.places.first

    base_items = @current_place ? @current_place.items : Item.none

    # 検索（選択中Place内）
    @q = params[:q].to_s.strip
    @items = base_items.order(created_at: :desc)
    if @q.present?
      @items = @items.where("name LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(@q)}%")
    end

    # 右ペイン選択Item（検索に左右されないよう base_items から拾う）
    @selected_item =
      if params[:item_id].present? && @current_place.present?
        base_items.find_by(id: params[:item_id])
      else
        nil
      end
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

  def new_button
    render partial: "places/new_button", locals: { parent_id: params[:parent_id] }
  end

  def new
    @parent = current_user.places.find_by(id: params[:parent_id])
    @place = current_user.places.new(parent_id: @parent&.id)

    return unless turbo_frame_request?

    render partial: "places/inline_form",
          locals: { place: @place, parent_id: @parent&.id }
  end

  def create
    @place = current_user.places.new(place_params)

    if @place.save
      respond_to do |format|
        format.turbo_stream do
          @place_tree = current_user.places.arrange(order: :name)

          render turbo_stream: [
            turbo_stream.replace(
              "place_tree",
              partial: "places/place_tree",
              locals: { place_tree: @place_tree, current_place: @place }
            ),
            turbo_stream.replace(
              "place_new",
              partial: "places/new_button",
              locals: { parent_id: @place.parent_id }
            )
          ]
        end

        format.html do
          redirect_to place_path(@place), notice: "Placeを作成しました"
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "place_new",
            partial: "places/inline_form",
            locals: { place: @place, parent_id: @place.parent_id }
          )
        end

        format.html do
          @parent = current_user.places.find_by(id: params.dig(:place, :parent_id))
          render :new, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def set_place
    @place = current_user.places.find(params[:id])
  end

  def place_params
    params.require(:place).permit(:name, :description, :parent_id)
  end
end
