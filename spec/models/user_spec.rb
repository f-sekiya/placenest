require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'destroy user data' do
    it 'destroys all places and items on destroy' do
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
