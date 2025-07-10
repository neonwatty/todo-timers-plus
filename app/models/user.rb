class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :timers, dependent: :destroy
  has_many :tags, -> { distinct }, through: :timers

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true,
            format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i }

  def active_timers
    timers.active
  end

  def total_time_today
    timers.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day)
          .sum(&:calculate_duration)
  end

  def total_time_tracked
    timers.sum(:duration)
  end

  def timer_stats
    {
      total_timers: timers.count,
      active_timers: timers.active.count,
      completed_timers: timers.completed.count,
      total_duration: timers.sum(:duration)
    }
  end

  def timers_by_date_range(start_date, end_date)
    timers.by_date_range(start_date, end_date)
  end

  def analytics_data(period = :week)
    case period
    when :week
      weekly_analytics
    when :month
      monthly_analytics
    else
      daily_analytics
    end
  end

  private

  def weekly_analytics
    start_date = 1.week.ago.beginning_of_day
    end_date = Time.current.end_of_day
    
    {
      total_time: timers.by_date_range(start_date, end_date).sum(&:calculate_duration),
      total_tasks: timers.by_date_range(start_date, end_date).count,
      daily_breakdown: (0..6).map do |days_ago|
        date = days_ago.days.ago.to_date
        day_timers = timers.where(created_at: date.beginning_of_day..date.end_of_day)
        {
          date: date,
          day_name: date.strftime('%a'),
          total_duration: day_timers.sum(&:calculate_duration),
          task_count: day_timers.count
        }
      end.reverse,
      top_tasks: calculate_top_tasks(start_date, end_date)
    }
  end

  def monthly_analytics
    start_date = 1.month.ago.beginning_of_day
    end_date = Time.current.end_of_day
    
    {
      total_time: timers.by_date_range(start_date, end_date).sum(&:calculate_duration),
      total_tasks: timers.by_date_range(start_date, end_date).count,
      weekly_breakdown: (0..3).map do |weeks_ago|
        week_start = weeks_ago.weeks.ago.beginning_of_week
        week_end = weeks_ago.weeks.ago.end_of_week
        week_timers = timers.by_date_range(week_start, week_end)
        {
          week_start: week_start,
          week_label: "Week of #{week_start.strftime('%b %d')}",
          total_duration: week_timers.sum(&:calculate_duration),
          task_count: week_timers.count
        }
      end.reverse,
      top_tasks: calculate_top_tasks(start_date, end_date)
    }
  end

  def daily_analytics
    today_timers = timers.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day)
    
    {
      total_time: today_timers.sum(&:calculate_duration),
      total_tasks: today_timers.count,
      hourly_breakdown: (0..23).map do |hour|
        hour_start = Date.current.beginning_of_day + hour.hours
        hour_end = hour_start + 1.hour
        hour_timers = timers.where(created_at: hour_start..hour_end)
        {
          hour: hour,
          label: hour_start.strftime('%l %p').strip,
          total_duration: hour_timers.sum(&:calculate_duration),
          task_count: hour_timers.count
        }
      end,
      top_tasks: calculate_top_tasks(Date.current.beginning_of_day, Date.current.end_of_day)
    }
  end

  def calculate_top_tasks(start_date, end_date)
    timer_data = timers.by_date_range(start_date, end_date)
    
    task_durations = Hash.new(0)
    timer_data.each do |timer|
      task_durations[timer.task_name] += timer.calculate_duration
    end
    
    task_durations.sort_by { |_, duration| -duration }.first(5)
  end
end
