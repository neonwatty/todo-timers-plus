class Timer < ApplicationRecord
  belongs_to :user
  has_many :timer_tags, dependent: :destroy
  has_many :tags, through: :timer_tags

  validates :task_name, presence: true
  validates :status, inclusion: { in: %w[running paused stopped completed] }

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
    total_seconds = calculate_duration
    hours = total_seconds / 3600
    minutes = (total_seconds % 3600) / 60
    seconds = total_seconds % 60
    
    if hours > 0
      sprintf('%02d:%02d:%02d', hours, minutes, seconds)
    else
      sprintf('%02d:%02d', minutes, seconds)
    end
  end
end
