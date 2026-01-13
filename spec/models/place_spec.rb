require 'rails_helper'

RSpec.describe Place, type: :model do
  let(:user) { User.create!(email: 'u1@example.com', password: 'password', nickname: 'u1') }

  describe 'deletion restrictions' do
    it 'raises Ancestry::AncestryException when parent has children' do
      parent = user.places.create!(name: 'parent')
      parent.children.create!(user: user, name: 'child')
      expect { parent.destroy }.to raise_error(Ancestry::AncestryException)
    end

    it 'blocks destroy when items exist' do
      p = user.places.create!(name: 'p')
      user.items.create!(place: p, name: 'x', quantity: 1, status: :active)
      expect(p.destroy).to be_falsey
      expect(p.errors.full_messages).not_to be_empty
    end
  end
end
