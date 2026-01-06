class Item < ApplicationRecord
  belongs_to :user
  belongs_to :place

  enum status: { active: 0, archived: 1 }

  validates :name, presence: true, length: { maximum: 80 }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
end
