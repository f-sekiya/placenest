module Places
  class IndexResponder
    def initialize(controller:, place_tree:, current_place:, selected_item:)
      @controller = controller
      @place_tree = place_tree
      @current_place = current_place
      @selected_item = selected_item
    end

    def call
      @controller.respond_to do |format|
        format.html { respond_html }
        format.turbo_stream { respond_turbo_stream }
      end
    end

    private

    def respond_html
      unless @controller.turbo_frame_request? || params[:item_id].present?
        @controller.render :index
        return
      end

      if accept_header.include?("text/vnd.turbo-stream.html")
        @controller.render turbo_stream: pane_updates_full
        return
      end

      case turbo_frame
      when "middle_pane"
        middle_html = @controller.render_to_string(partial: "places/middle_pane")
        @controller.render html: "<turbo-frame id=\"middle_pane\">#{middle_html}</turbo-frame>".html_safe
      when "right_pane"
        @controller.render partial: "places/right_pane_frame",
                           locals: { current_place: @current_place, selected_item: @selected_item }
      else
        @controller.render :index
      end
    end

    def respond_turbo_stream
      if params[:item_id].present?
        @controller.render turbo_stream: pane_updates_full
        return
      end

      unless @controller.turbo_frame_request?
        @controller.head :ok
        return
      end

      case turbo_frame
      when "middle_pane"
        @controller.render turbo_stream: pane_updates_full
      when "right_pane"
        @controller.render turbo_stream: pane_updates_middle_and_right
      else
        @controller.head :ok
      end
    end

    def pane_updates_full
      Places::PaneUpdates.full(
        controller: @controller,
        place_tree: @place_tree,
        current_place: @current_place,
        selected_item: @selected_item
      )
    end

    def pane_updates_middle_and_right
      Places::PaneUpdates.middle_and_right(
        controller: @controller,
        current_place: @current_place,
        selected_item: @selected_item
      )
    end

    def accept_header
      @controller.request.headers["Accept"].to_s
    end

    def turbo_frame
      @controller.request.headers["Turbo-Frame"].to_s
    end

    def params
      @controller.params
    end
  end
end
