class PlacesController < ApplicationController
  layout "explorer", only: [:index]
  before_action :authenticate_user!
  before_action :set_place, only: [:show, :edit, :update, :destroy]

  def index
    build_place_tree
    set_current_place
    prepare_new_place
    prepare_items
    find_selected_item

    respond_to do |format|
      format.html do
        # If this is a Turbo frame navigation (or explicit item selection),
        # prefer turbo-stream when the client asks for it. If the client
        # requested plain HTML (common with some Accept headers), return a
        # right_pane-wrapped <turbo-frame> HTML fragment and include a small
        # inline script to toggle the selected row in the middle pane. This
        # ensures right_pane is replaced and the middle selection is visible
        # even when turbo-stream is not negotiated.
        if turbo_frame_request? || params[:item_id].present?
          accept = request.headers['Accept'].to_s

          if accept.include?('text/vnd.turbo-stream.html')
            render turbo_stream: [
              turbo_stream.update(
                'place_tree',
                partial: 'places/place_tree',
                locals: { place_tree: @place_tree, current_place: @current_place }
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
          else
            # Render right pane wrapped in a turbo-frame so Turbo will replace it.
            right_html = render_to_string(partial: 'places/right_pane', locals: { current_place: @current_place, selected_item: @selected_item })

            # Inline JS: clear existing selection and mark the selected row.
            selected_id = @selected_item&.id
            js = <<~JS
              <script>
              (function(){
                try{
                  var rows = document.querySelectorAll('.items-table tbody tr');
                  rows.forEach(function(r){ r.classList.remove('is-selected'); });
                  var row = document.querySelector('.items-table tbody tr[data-item-id="#{selected_id}"]');
                  if(row) row.classList.add('is-selected');
                }catch(e){ console.error(e); }
              })();
              </script>
            JS

            render html: "<turbo-frame id=\"right_pane\">#{right_html}#{js}</turbo-frame>".html_safe
          end
        else
          render :index
        end
      end

      format.turbo_stream do
        # Handle turbo requests robustly: if item_id param present, update both middle and right panes
        if params[:item_id].present?
          render turbo_stream: [
            turbo_stream.update(
              'place_tree',
              partial: 'places/place_tree',
              locals: { place_tree: @place_tree, current_place: @current_place }
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

        elsif turbo_frame_request?
          frame = request.headers['Turbo-Frame']

          case frame
          when 'middle_pane'
            render turbo_stream: [
              turbo_stream.update(
                'place_tree',
                partial: 'places/place_tree',
                locals: { place_tree: @place_tree, current_place: @current_place }
              ),
              turbo_stream.update(
                'middle_pane',
                partial: 'places/middle_pane'
              )
            ]

          when 'right_pane'
            render turbo_stream: [
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

          else
            head :ok
          end

        else
          head :ok
        end
      end
    end
  end

  def show
    @children = @place.children.order(:id)
    # show ページの Item も名前順にする
    @items = @place.items.order(:name)
  end

  def destroy
    deleted_id = @place.id
    return_place = compute_return_place(deleted_id, params[:return_place_id])

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

  def edit
    @parent = current_user.places.find_by(id: @place.parent_id)

    return unless turbo_frame_request?

    render partial: "places/inline_form",
           locals: { place: @place, parent_id: @parent&.id }
  end

  def create
    @place = current_user.places.new(place_params)

    # ルートに追加（親なし）を強制
    @place.parent_id = nil if params[:place_scope] == "root"

    current_place = resolve_current_place_from(params[:return_place_id])

    if @place.save
      @place_tree = current_user.places.arrange(order: :name)
      respond_place_create_success(current_place)
    else
      respond_place_create_failure(current_place)
    end
  end

  def update
    current_place = resolve_current_place_from(params[:return_place_id])

    if @place.update(place_params)
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
          redirect_to root_path(place_id: current_place&.id), notice: "Placeを更新しました"
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
          render :edit, status: :unprocessable_entity
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

  def build_place_tree
    @place_tree = current_user.places.arrange(order: :name)
    ensure_unclassified_first!
  end

  def ensure_unclassified_first!
    return unless (unclassified = current_user.unclassified_place)

    root_key = @place_tree.keys.find { |p| p.id == unclassified.id }
    return unless root_key

    val = @place_tree.delete(root_key)
    @place_tree = { root_key => val }.merge(@place_tree)
  end

  def set_current_place
    @current_place = if params[:place_id].present?
                       current_user.places.find_by(id: params[:place_id])
                     else
                       current_user.unclassified_place
                     end
    @current_place ||= current_user.places.first
  end

  def prepare_new_place
    @new_place = current_user.places.new(parent_id: @current_place&.id)
  end

  def prepare_items
    @base_items = @current_place ? @current_place.items : Item.none
    @q = params[:q].to_s.strip
    @items = @base_items.order(:name)
    return unless @q.present?

    escaped = ActiveRecord::Base.sanitize_sql_like(@q)
    @items = @items.where("name LIKE ?", "%#{escaped}%")
  end

  def find_selected_item
    @selected_item = if params[:item_id].present? && @current_place.present?
                       @base_items.find_by(id: params[:item_id])
                     end
  end

  def compute_return_place(deleted_id, return_place_id)
    return_place = resolve_current_place_from(return_place_id)
    return_place = (@place.parent || current_user.unclassified_place || current_user.places.where.not(id: deleted_id).first) if return_place&.id == deleted_id
    return_place
  end

  def respond_place_create_success(current_place)
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
  end

  def respond_place_create_failure(current_place)
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

  # return_place_id が無効/空でも必ず落ち着く場所を返す
  def resolve_current_place_from(id)
    current_user.places.find_by(id: id) ||
      current_user.unclassified_place ||
      current_user.places.first
  end
end
