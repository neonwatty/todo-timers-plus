class Timer < ApplicationRecord
  belongs_to :user
  has_many :timer_tags, dependent: :destroy
  has_many :tags, through: :timer_tags

  validates :task_name, presence: true
  validates :status, inclusion: { in: %w[pending running paused stopped completed] }
  validates :duration, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :set_default_status, on: :create
  after_save :create_tag_associations, if: :saved_change_to_tags?

  scope :active, -> { where(status: ['running', 'paused']) }
  scope :completed, -> { where(status: ['stopped', 'completed']) }
  scope :by_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }
  scope :by_week, ->(date) { by_date_range(date.beginning_of_week, date.end_of_week) }
  scope :by_month, ->(date) { by_date_range(date.beginning_of_month, date.end_of_month) }

  def running?
    status == 'running'
  end

  def paused?
    status == 'paused'
  end

  def calculate_duration
    return 0 unless start_time
    
    if end_time
      (end_time - start_time).to_i
    elsif running?
      (Time.current - start_time).to_i
    else
      duration || 0
    end
  end

  def formatted_duration
    total_seconds = duration || calculate_duration
    hours = total_seconds / 3600
    minutes = (total_seconds % 3600) / 60
    seconds = total_seconds % 60
    
    sprintf('%02d:%02d:%02d', hours, minutes, seconds)
  end

  def stopped?
    status == 'stopped'
  end

  def completed?
    status == 'completed'
  end

  def parse_tags
    return [] if self[:tags].blank?
    self[:tags].split(',').map(&:strip)
  end

  def start!
    update!(status: 'running', start_time: Time.current)
  end

  def pause!
    if running?
      update!(
        status: 'paused',
        duration: calculate_duration
      )
    end
  end

  def resume!
    if paused?
      update!(
        status: 'running',
        start_time: Time.current - duration.seconds
      )
    end
  end

  def stop!
    if running? || paused?
      update!(
        status: 'stopped',
        end_time: Time.current,
        duration: calculate_duration
      )
    end
  end

  private

  def set_default_status
    self.status ||= 'pending'
  end

  def create_tag_associations
    return if self[:tags].blank?
    
    # Clear existing tags
    timer_tags.destroy_all
    
    # Create new tag associations
    tag_names = self[:tags].split(',').map(&:strip).map(&:downcase).uniq
    tag_names.each do |tag_name|
      tag = Tag.find_or_create_by(name: tag_name)
      timer_tags.create(tag: tag)
    end
  end
end
