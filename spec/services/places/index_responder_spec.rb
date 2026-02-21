require "rails_helper"

RSpec.describe Places::IndexResponder do
  class FakeFormat
    def initialize(format)
      @format = format
    end

    def html
      yield if @format == :html
    end

    def turbo_stream
      yield if @format == :turbo_stream
    end
  end

  class FakeTurboStreamBuilder
    def update(target, partial:, locals: nil)
      { target: target, partial: partial, locals: locals }
    end
  end

  class FakeController
    attr_reader :params, :request, :render_args, :head_status

    def initialize(format:, params: {}, headers: {})
      @format = format
      @params = ActionController::Parameters.new(params)
      @request = Struct.new(:headers).new(headers)
      @turbo_stream = FakeTurboStreamBuilder.new
    end

    def respond_to
      yield FakeFormat.new(@format)
    end

    def turbo_frame_request?
      request.headers["Turbo-Frame"].to_s != ""
    end

    def render(*args, **kwargs)
      @render_args = { args: args, kwargs: kwargs }
    end

    def head(status)
      @head_status = status
    end

    def turbo_stream
      @turbo_stream
    end

    def render_to_string(partial:)
      "rendered:#{partial}"
    end
  end

  let(:place_tree) { { double("place") => {} } }
  let(:current_place) { double("current_place") }
  let(:selected_item) { double("selected_item") }

  before do
    allow(Places::PaneUpdates).to receive(:full).and_return([:full])
    allow(Places::PaneUpdates).to receive(:middle_and_right).and_return([:middle_and_right])
  end

  it "html かつ turbo-stream accept 時は full 更新を返す" do
    controller = FakeController.new(
      format: :html,
      params: { item_id: 1 },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    )

    described_class.new(
      controller: controller,
      place_tree: place_tree,
      current_place: current_place,
      selected_item: selected_item
    ).call

    expect(controller.render_args[:kwargs]).to eq({ turbo_stream: [:full] })
  end

  it "html かつ Turbo-Frame=middle_pane の時は middle_pane_frame partial を返す" do
    controller = FakeController.new(
      format: :html,
      headers: { "Turbo-Frame" => "middle_pane", "Accept" => "text/html" }
    )

    described_class.new(
      controller: controller,
      place_tree: place_tree,
      current_place: current_place,
      selected_item: selected_item
    ).call

    expect(controller.render_args[:kwargs]).to eq({ partial: "places/middle_pane_frame" })
  end

  it "turbo_stream かつ Turbo-Frame=right_pane の時は middle_and_right 更新を返す" do
    controller = FakeController.new(
      format: :turbo_stream,
      headers: { "Turbo-Frame" => "right_pane" }
    )

    described_class.new(
      controller: controller,
      place_tree: place_tree,
      current_place: current_place,
      selected_item: selected_item
    ).call

    expect(controller.render_args[:kwargs]).to eq({ turbo_stream: [:middle_and_right] })
  end
end
