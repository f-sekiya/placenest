require 'rails_helper'

RSpec.describe Item, type: :model do
  let(:user) { User.create!(email: 'u@example.com', password: 'password', nickname: 'tester') }
  let(:place) { user.places.create!(name: 'Shelf') }

  it '有効な属性であれば有効であること' do
    item = user.items.new(name: 'Apple', quantity: 2, status: :active, place: place)
    expect(item).to be_valid
  end
  it '名前がなければ無効であること' do
    item = user.items.new(quantity: 1, place: place)
    expect(item).not_to be_valid
    expect(item.errors[:name]).to include(I18n.t('errors.messages.blank'))
  end
  it '数量は整数で 0 より大きいことを検証すること' do
    item = user.items.new(name: 'A', quantity: 0, place: place)
    expect(item).not_to be_valid
    expect(item.errors[:quantity]).to be_present
  end
  it 'status の enum を持つこと' do
    expect(Item.statuses.keys).to include('active', 'archived')
  end
end
