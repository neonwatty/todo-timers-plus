class Tag < ApplicationRecord
  has_many :timer_tags, dependent: :restrict_with_error
  has_many :timers, through: :timer_tags
  has_many :users, -> { distinct }, through: :timers

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  before_validation :normalize_name
  before_validation :set_default_color, on: :create

  def self.find_or_create_by_names(names)
    return [] if names.blank?
    
    names = names.is_a?(String) ? names.split(',') : names
    names.map(&:strip).map(&:downcase).uniq.map do |name|
      find_or_create_by(name: name)
    end
  end

  private

  def normalize_name
    self.name = name.downcase.strip if name.present?
  end

  def set_default_color
    self.color ||= 'gray'
  end
end
