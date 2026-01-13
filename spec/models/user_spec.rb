require 'rails_helper'

RSpec.describe User, type: :model do
  it 'ユーザー作成後に未分類の Place が作成されること' do
    user = User.create!(email: 'new@example.com', password: 'password', nickname: 'newuser')
    expect(user.unclassified_place).to be_present
    expect(user.unclassified_place.name).to eq('未分類')
  end

  describe 'ユーザーデータ削除' do
    it '削除時に関連する places と items がすべて削除されること' do
      u = User.create!(email: 'del@test.com', password: 'password', nickname: 'del')
      root = u.places.create!(name: 'root')
      child = root.children.create!(user: u, name: 'child')
      u.items.create!(place: child, name: 'it', quantity: 1, status: :active)

      expect { u.destroy }.to change { User.exists?(u.id) }.from(true).to(false)
      expect(Place.where(user_id: u.id).exists?).to be_falsey
      expect(Item.where(user_id: u.id).exists?).to be_falsey
    end
  end
end
