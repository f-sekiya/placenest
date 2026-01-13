class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Do not set `dependent` here; User deletion is centrally controlled
  # by `before_destroy :destroy_user_data` to ensure order and avoid
  # double-destroy/ordering issues with Place#orphan_strategy.
  has_many :places
  has_many :items

  after_create_commit :ensure_unclassified_place

  def unclassified_place
    places.find_by(name: '未分類')
  end

  before_destroy :destroy_user_data

  private

  def ensure_unclassified_place
    places.find_or_create_by!(name: '未分類')
  end

  def destroy_user_data
    ActiveRecord::Base.transaction do
      # 1) destroy items first to avoid Place deletion being blocked by items
      items.find_each(&:destroy!)

      # 2) destroy places from deepest to shallowest using Ruby-calculated depth
      sorted_places = places.to_a.sort_by do |pl|
        if pl.respond_to?(:depth) && pl.depth
          -pl.depth
        else
          -pl.ancestry.to_s.split('/').reject(&:empty?).size
        end
      end

      sorted_places.each(&:destroy!)
    rescue ActiveRecord::RecordNotDestroyed => e
      record = e.respond_to?(:record) ? e.record : nil
      msg = if record.respond_to?(:errors)
              record.errors.full_messages.join(', ')
            else
              e.message
            end
      errors.add(:base, "Failed to destroy record: #{msg}")
      throw :abort
    end
  end

  validates :nickname, presence: true, length: { maximum: 20 }
end
