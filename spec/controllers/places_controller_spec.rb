require 'rails_helper'

RSpec.describe PlacesController, type: :controller do
  let(:user) { User.create!(email: 'a@ex.com', password: 'password', nickname: 'n') }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'place_tree の先頭に未分類が来て、items が名前順に並んでいること' do
      # ensure unclassified exists
      unclassified = user.unclassified_place
      user.places.create!(name: 'B')

      # create items under current place (unclassified)
      user.items.create!(name: 'Banana', quantity: 1, place: unclassified)
      user.items.create!(name: 'Apple', quantity: 1, place: unclassified)

      get :index
      expect(assigns(:place_tree).keys.first.id).to eq(unclassified.id)

      names = assigns(:items).map(&:name)
      expect(names).to eq(names.sort)
    end
  end
end
