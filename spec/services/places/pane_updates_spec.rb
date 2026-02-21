require "rails_helper"

RSpec.describe Places::PaneUpdates do
  let(:turbo_stream_builder) { instance_double("TurboStreamBuilder") }
  let(:controller) { instance_double("Controller", turbo_stream: turbo_stream_builder) }
  let(:place_tree) { { double("place") => {} } }
  let(:current_place) { double("current_place") }
  let(:selected_item) { double("selected_item") }

  before do
    allow(turbo_stream_builder).to receive(:update) do |target, partial:, locals: nil|
      { target: target, partial: partial, locals: locals }
    end
  end

  describe ".full" do
    it "place_tree/middle_pane/right_pane を返す" do
      updates = described_class.full(
        controller: controller,
        place_tree: place_tree,
        current_place: current_place,
        selected_item: selected_item
      )

      expect(updates.map { |u| u[:target] }).to eq(%w[place_tree middle_pane right_pane])
      expect(updates.first[:locals]).to eq({ place_tree: place_tree, current_place: current_place })
      expect(updates.last[:locals]).to eq({ current_place: current_place, selected_item: selected_item })
    end

    it "include_left_quick が true の時は left_quick を追加する" do
      updates = described_class.full(
        controller: controller,
        place_tree: place_tree,
        current_place: current_place,
        selected_item: selected_item,
        include_left_quick: true
      )

      expect(updates.map { |u| u[:target] }).to eq(%w[place_tree left_quick middle_pane right_pane])
    end
  end

  describe ".middle_and_right" do
    it "middle_pane/right_pane を返す" do
      updates = described_class.middle_and_right(
        controller: controller,
        current_place: current_place,
        selected_item: selected_item
      )

      expect(updates.map { |u| u[:target] }).to eq(%w[middle_pane right_pane])
      expect(updates.last[:locals]).to eq({ current_place: current_place, selected_item: selected_item })
    end
  end
end
