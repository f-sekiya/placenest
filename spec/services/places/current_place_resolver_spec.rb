require "rails_helper"

RSpec.describe Places::CurrentPlaceResolver do
  let(:user) { User.create!(email: "resolver@example.com", password: "password", nickname: "resolver") }
  let(:resolver) { described_class.new(user: user) }
  let!(:place_a) { user.places.create!(name: "A") }
  let!(:place_b) { user.places.create!(name: "B") }

  describe "#for_index" do
    it "place_id が有効な場合はその place を返す" do
      expect(resolver.for_index(place_id: place_a.id)).to eq(place_a)
    end

    it "place_id が空の場合は未分類 place を返す" do
      expect(resolver.for_index(place_id: nil)).to eq(user.unclassified_place)
    end
  end

  describe "#for_item" do
    it "params_place_id を優先して返す" do
      expect(resolver.for_item(params_place_id: place_a.id, fallback_place_id: place_b.id)).to eq(place_a)
    end

    it "params_place_id が空なら fallback_place_id を返す" do
      expect(resolver.for_item(params_place_id: nil, fallback_place_id: place_b.id)).to eq(place_b)
    end

    it "どちらも空なら未分類 place を返す" do
      expect(resolver.for_item(params_place_id: nil, fallback_place_id: nil)).to eq(user.unclassified_place)
    end
  end

  describe "#for_return" do
    it "return_place_id が有効ならそれを返す" do
      result = resolver.for_return(return_place_id: place_a.id, deleted_id: place_b.id, fallback_parent: nil)
      expect(result).to eq(place_a)
    end

    it "return_place_id が deleted_id と同じなら fallback_parent を返す" do
      result = resolver.for_return(return_place_id: place_a.id, deleted_id: place_a.id, fallback_parent: place_b)
      expect(result).to eq(place_b)
    end
  end
end
