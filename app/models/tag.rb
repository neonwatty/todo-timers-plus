class Tag < ApplicationRecord
  has_many :timer_tags, dependent: :destroy
  has_many :timers, through: :timer_tags

  validates :name, presence: true, uniqueness: true
  validates :color, format: { with: /\A#[0-9a-fA-F]{6}\z/, message: 'must be a valid hex color' }

  before_validation :set_default_color, on: :create

  private

  def set_default_color
    self.color ||= '#6B7280'
  end
end
