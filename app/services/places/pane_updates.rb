module Places
  class PaneUpdates
    class << self
      def full(controller:, place_tree:, current_place:, selected_item:, include_left_quick: false)
        streams = [
          controller.turbo_stream.update(
            "place_tree",
            partial: "places/place_tree",
            locals: { place_tree: place_tree, current_place: current_place }
          ),
          controller.turbo_stream.update(
            "middle_pane",
            partial: "places/middle_pane"
          ),
          controller.turbo_stream.update(
            "right_pane",
            partial: "places/right_pane",
            locals: { current_place: current_place, selected_item: selected_item }
          )
        ]

        if include_left_quick
          streams.insert(
            1,
            controller.turbo_stream.update(
              "left_quick",
              partial: "places/left_quick"
            )
          )
        end

        streams
      end

      def middle_and_right(controller:, current_place:, selected_item:)
        [
          controller.turbo_stream.update(
            "middle_pane",
            partial: "places/middle_pane"
          ),
          controller.turbo_stream.update(
            "right_pane",
            partial: "places/right_pane",
            locals: { current_place: current_place, selected_item: selected_item }
          )
        ]
      end
    end
  end
end
