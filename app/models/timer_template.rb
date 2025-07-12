class TimerTemplate < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :timer_type, inclusion: { in: %w[stopwatch countdown] }
  validates :target_duration, presence: true, numericality: { greater_than: 0 }, if: :countdown?
  validates :task_name, length: { maximum: 255 }
  validates :tags, length: { maximum: 1000 }
  
  scope :most_used, -> { order(usage_count: :desc) }
  scope :popular, -> { order(usage_count: :desc) }
  scope :recently_used, -> { order(last_used_at: :desc) }
  scope :by_type, ->(type) { where(timer_type: type) }
  
  before_validation :set_defaults
  
  def countdown?
    timer_type == 'countdown'
  end
  
  def stopwatch?
    timer_type == 'stopwatch'
  end
  
  def parse_tags
    return [] if tags.blank?
    tags.split(',').map(&:strip).reject(&:blank?)
  end
  
  def formatted_duration
    return "—" unless countdown? && target_duration.present?
    Timer.format_seconds(target_duration)
  end
  
  def increment_usage!
    increment!(:usage_count)
    update_column(:last_used_at, Time.current)
  end
  
  # Create a new timer from this template
  def create_timer_for_user(user, overrides = {})
    # Create timer with basic attributes
    timer = Timer.new(
      user: user,
      task_name: task_name || "New Timer",
      timer_type: timer_type || "stopwatch",
      status: 'stopped'
    )
    
    # Add countdown-specific attributes
    if countdown? && target_duration.present?
      timer.target_duration = target_duration
      timer.remaining_duration = target_duration
    end
    
    # Add tags if present (use column directly, not association)
    timer[:tags] = tags if tags.present?
    
    # Apply any overrides
    overrides.each { |key, value| timer.send("#{key}=", value) }
    
    # Save and track usage
    if timer.save
      increment_usage!
    end
    
    timer
  end
  
  # Create template from existing timer
  def self.create_from_timer(timer, name, user = nil)
    user ||= timer.user
    
    template_attributes = {
      user: user,
      name: name,
      task_name: timer.task_name,
      timer_type: timer.timer_type || 'stopwatch',
      tags: timer[:tags]
    }
    
    # Add countdown-specific attributes
    if timer.countdown? && timer.target_duration.present?
      template_attributes[:target_duration] = timer.target_duration
    end
    
    create(template_attributes)
  end
  
  private
  
  def set_defaults
    self.timer_type ||= 'stopwatch'
    self.usage_count ||= 0
  end
end
