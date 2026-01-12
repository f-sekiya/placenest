class Place < ApplicationRecord
  has_ancestry orphan_strategy: :restrict

  belongs_to :user
  has_many :items, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 50 }

  def path_string(separator: " / ")
    path.map(&:name).join(separator)
  end
end
