require 'rails_helper'

RSpec.describe ItemsController, type: :controller do
  let(:user) { User.create!(email: 'items@example.com', password: 'password', nickname: 'items-user') }
  let(:place) { user.places.create!(name: 'Shelf') }

  before do
    sign_in user
  end

  describe 'GET #new' do
    it '未分類 place を初期選択にすること' do
      get :new

      expect(response).to have_http_status(:ok)
      item = controller.instance_variable_get(:@item)
      expect(item.place).to eq(user.unclassified_place)
    end

    it 'place_id 指定時はその place を初期選択にすること' do
      get :new, params: { place_id: place.id }

      expect(response).to have_http_status(:ok)
      item = controller.instance_variable_get(:@item)
      expect(item.place).to eq(place)
    end
  end

  describe 'POST #create' do
    it '有効なパラメータで item を作成すること' do
      expect do
        post :create, params: { item: { name: 'Cable', quantity: 2, status: 'active', place_id: place.id } }
      end.to change(Item, :count).by(1)

      created_item = Item.order(:id).last
      expect(created_item.user).to eq(user)
      expect(created_item.place).to eq(place)
      expect(response).to redirect_to(root_path(place_id: place.id, item_id: created_item.id))
    end

    it '無効パラメータでは作成失敗し 422 を返すこと' do
      expect do
        post :create, params: { item: { name: '', quantity: 0, status: 'active', place_id: place.id } }
      end.not_to change(Item, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #quick_create' do
    it '未分類 place に item を作成すること' do
      expect do
        post :quick_create, params: { item: { name: 'Tape', quantity: 1, status: 'active' } }
      end.to change(Item, :count).by(1)

      created_item = Item.order(:id).last
      expect(created_item.place).to eq(user.unclassified_place)
      expect(response).to redirect_to(root_path(place_id: user.unclassified_place.id, item_id: created_item.id))
    end
  end

  describe 'PATCH #update' do
    let!(:item) { user.items.create!(name: 'Old', quantity: 1, status: :active, place: place) }

    it '有効なパラメータで更新すること' do
      patch :update, params: { id: item.id, item: { name: 'New Name', quantity: 3, place_id: place.id, status: 'active' } }

      expect(response).to redirect_to(root_path(place_id: place.id, item_id: item.id))
      expect(item.reload.name).to eq('New Name')
      expect(item.quantity).to eq(3)
    end

    it '無効パラメータでは 422 で edit を再描画すること' do
      patch :update, params: { id: item.id, item: { name: '', quantity: 0, place_id: place.id, status: 'active' } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:edit)
      expect(item.reload.name).to eq('Old')
    end
  end

  describe 'DELETE #destroy' do
    let!(:item) { user.items.create!(name: 'Trash', quantity: 1, status: :active, place: place) }

    it '対象 item を削除すること' do
      expect do
        delete :destroy, params: { place_id: place.id, id: item.id }
      end.to change(Item, :count).by(-1)

      expect(response).to redirect_to(root_path(place_id: place.id))
    end
  end
end
