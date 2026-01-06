class Place < ApplicationRecord
  has_ancestry

  belongs_to :user
  has_many :items, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 50 }
end
