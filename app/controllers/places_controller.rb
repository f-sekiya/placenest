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

    # 左の「＋」用（デフォルトは現在地の子を作る）
    @new_place = current_user.places.new(parent_id: @current_place&.id)

    base_items = @current_place ? @current_place.items : Item.none

    # 検索（選択中Place内）
    @q = params[:q].to_s.strip
    @items = base_items.order(created_at: :desc)
    if @q.present?
      escaped = ActiveRecord::Base.sanitize_sql_like(@q)
      @items = @items.where("name LIKE ?", "%#{escaped}%")
    end

    # 右ペイン選択Item（検索に左右されないよう base_items から拾う）
    @selected_item =
      if params[:item_id].present? && @current_place.present?
        base_items.find_by(id: params[:item_id])
      end
  end

  def show
    @children = @place.children.order(:id)
    @items = @place.items.order(:id)
  end

  def destroy
    deleted_id = @place.id

    return_place = resolve_current_place_from(params[:return_place_id])

    # 「削除するPlace自身」を戻り先にしていた場合はフォールバック
    if return_place&.id == deleted_id
      return_place = @place.parent ||
                     current_user.unclassified_place ||
                     current_user.places.where.not(id: deleted_id).first
    end

    if @place.destroy
      redirect_to root_path(place_id: return_place&.id), notice: "Placeを削除しました"
    else
      redirect_to root_path(place_id: return_place&.id), alert: @place.errors.full_messages.to_sentence
    end
  rescue Ancestry::AncestryException => e
    redirect_to root_path(place_id: return_place&.id), alert: e.message
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

    # ルートに追加（親なし）を強制
    if params[:place_scope] == "root"
      @place.parent_id = nil
    end

    current_place = resolve_current_place_from(params[:return_place_id])

    if @place.save
      @place_tree = current_user.places.arrange(order: :name)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(
              "place_tree",
              partial: "places/place_tree",
              locals: { place_tree: @place_tree, current_place: current_place }
            ),
            turbo_stream.update(
              "place_new",
              partial: "places/place_new",
              locals: {
                place: current_user.places.new(parent_id: current_place&.id),
                parent_id: current_place&.id,
                open: false
              }
            )
          ]
        end

        format.html do
          redirect_to root_path(place_id: current_place&.id), notice: "Placeを作成しました"
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "place_new",
            partial: "places/place_new",
            locals: { place: @place, parent_id: current_place&.id, open: true }
          )
        end

        format.html do
          @parent = current_user.places.find_by(id: @place.parent_id)
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

  # return_place_id が無効/空でも必ず落ち着く場所を返す
  def resolve_current_place_from(id)
    current_user.places.find_by(id: id) ||
      current_user.unclassified_place ||
      current_user.places.first
  end
end
