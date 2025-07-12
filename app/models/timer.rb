class Timer < ApplicationRecord
  belongs_to :user
  has_many :timer_tags, dependent: :destroy
  has_many :tag_objects, through: :timer_tags, source: :tag

  validates :task_name, presence: true
  validates :status, inclusion: { in: %w[pending running paused stopped completed expired] }
  validates :duration, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :target_duration, numericality: { greater_than: 0 }, allow_nil: true
  validates :remaining_duration, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :notes, length: { maximum: 2000 }

  before_validation :set_default_status, on: :create
  after_save :create_tag_associations, if: :saved_change_to_tags?

  scope :active, -> { where(status: ['running', 'paused']) }
  scope :completed, -> { where(status: ['stopped', 'completed', 'expired']) }
  scope :expired, -> { where(status: 'expired') }
  scope :countdown, -> { where.not(target_duration: nil) }
  scope :stopwatch, -> { where(target_duration: nil) }
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
      [(end_time - start_time).to_i, 0].max
    elsif running?
      [(Time.current - start_time).to_i, 0].max
    else
      duration || 0
    end
  end
  
  # Get current duration (for tests and other uses)
  def current_duration
    calculate_duration
  end

  def formatted_duration
    total_seconds = countdown? ? calculate_remaining_time : (duration || calculate_duration)
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

  def expired?
    status == 'expired' || (countdown? && running? && calculate_remaining_time <= 0)
  end

  def countdown?
    target_duration.present?
  end

  def stopwatch?
    target_duration.nil?
  end

  # Calculate remaining time for countdown timers
  def calculate_remaining_time
    return 0 unless countdown?
    
    if running?
      # Timer is running, calculate based on elapsed time
      elapsed = Time.current - start_time
      remaining = (remaining_duration || target_duration) - elapsed.to_i
      [remaining, 0].max # Don't go negative
    elsif paused?
      # Timer is paused, use stored remaining duration
      remaining_duration || target_duration
    elsif expired?
      0
    else
      # Timer hasn't started yet or was reset
      target_duration
    end
  end

  # Get time for display (remaining for countdown, elapsed for stopwatch)
  def display_time
    countdown? ? calculate_remaining_time : calculate_duration
  end

  # Format time for countdown display
  def formatted_remaining_time
    total_seconds = calculate_remaining_time
    hours = total_seconds / 3600
    minutes = (total_seconds % 3600) / 60
    seconds = total_seconds % 60
    
    sprintf('%02d:%02d:%02d', hours, minutes, seconds)
  end

  # Check if timer should expire
  def should_expire?
    countdown? && running? && calculate_remaining_time <= 0
  end

  # Percentage complete for progress bars
  def percentage_complete
    return 0 unless countdown? && target_duration > 0
    
    remaining = calculate_remaining_time
    elapsed = target_duration - remaining
    (elapsed.to_f / target_duration * 100).round(2)
  end
  
  # Alias for view compatibility
  alias_method :progress_percentage, :percentage_complete
  
  # Class method to format seconds
  def self.format_seconds(total_seconds)
    hours = total_seconds / 3600
    minutes = (total_seconds % 3600) / 60
    seconds = total_seconds % 60
    
    sprintf('%02d:%02d:%02d', hours, minutes, seconds)
  end

  def parse_tags
    return [] if self[:tags].blank?
    self[:tags].split(',').map(&:strip)
  end

  def start!
    if countdown?
      # For countdown timers, store the remaining duration
      update!(
        status: 'running',
        start_time: Time.current,
        remaining_duration: target_duration
      )
    else
      # For stopwatch timers
      update!(status: 'running', start_time: Time.current)
    end
  end

  def pause!
    if running?
      if countdown?
        # Store remaining time when pausing countdown
        calculated_remaining = calculate_remaining_time
        calculated_duration = calculate_duration
        
        # Ensure values are non-negative
        calculated_remaining = [calculated_remaining, 0].max
        calculated_duration = [calculated_duration, 0].max
        
        update!(
          status: 'paused',
          remaining_duration: calculated_remaining,
          duration: calculated_duration
        )
      else
        # For stopwatch timers
        calculated_duration = calculate_duration
        calculated_duration = [calculated_duration, 0].max
        
        update!(
          status: 'paused',
          duration: calculated_duration
        )
      end
    end
  end

  def resume!
    if paused?
      if countdown?
        # Resume countdown with stored remaining time
        update!(
          status: 'running',
          start_time: Time.current,
          end_time: nil
        )
      else
        # For stopwatch timers
        update!(
          status: 'running',
          start_time: Time.current - duration.seconds,
          end_time: nil
        )
      end
    end
  end

  def stop!
    if running? || paused?
      calculated_duration = calculate_duration
      calculated_duration = [calculated_duration, 0].max
      
      update!(
        status: 'stopped',
        end_time: Time.current,
        duration: calculated_duration
      )
    end
  end

  def reset!
    if countdown?
      update!(
        status: 'stopped',
        start_time: nil,
        end_time: nil,
        duration: 0,
        remaining_duration: target_duration,
        completed_at: nil
      )
    else
      update!(
        status: 'stopped',
        start_time: nil,
        end_time: nil,
        duration: 0
      )
    end
  end

  def expire!
    if countdown? && running?
      update!(
        status: 'expired',
        end_time: Time.current,
        completed_at: Time.current,
        duration: target_duration,
        remaining_duration: 0
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
