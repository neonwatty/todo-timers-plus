class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :timers, dependent: :destroy
  has_many :timer_templates, dependent: :destroy
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
    case period.to_s
    when 'week'
      weekly_analytics
    when 'month'
      monthly_analytics
    when 'day'
      daily_analytics
    else
      weekly_analytics
    end
  end
  
  # Get analytics by tags
  def tag_analytics(period)
    case period.to_s
    when 'day'
      start_date = Date.current.beginning_of_day
      end_date = Date.current.end_of_day
    when 'week'
      start_date = 1.week.ago.beginning_of_day
      end_date = Time.current.end_of_day
    when 'month'
      start_date = 1.month.ago.beginning_of_day
      end_date = Time.current.end_of_day
    else
      start_date = 1.week.ago.beginning_of_day
      end_date = Time.current.end_of_day
    end
    
    # Get all timers in the period
    period_timers = timers.by_date_range(start_date, end_date)
    
    # Aggregate by tags
    tag_durations = Hash.new(0)
    tag_counts = Hash.new(0)
    
    period_timers.find_each do |timer|
      tags = timer.parse_tags
      duration = timer.duration || 0
      if tags.empty?
        tag_durations["Untagged"] += duration
        tag_counts["Untagged"] += 1
      else
        tags.each do |tag|
          tag_durations[tag] += duration
          tag_counts[tag] += 1
        end
      end
    end
    
    # Format for chart
    tag_durations.map do |tag, duration|
      {
        name: tag,
        duration: duration,
        count: tag_counts[tag]
      }
    end.sort_by { |t| -t[:duration] }.first(10)
  end
  
  # Calculate streak data for user
  def calculate_streak_data
    today = Date.current
    dates_with_timers = timers.pluck(:created_at).map(&:to_date).uniq.sort
    
    return { current_streak: 0, longest_streak: 0, calendar_data: {} } if dates_with_timers.empty?
    
    # Calculate current streak
    current_streak = 0
    date = today
    while dates_with_timers.include?(date)
      current_streak += 1
      date -= 1.day
    end
    
    # Calculate longest streak
    longest_streak = 0
    temp_streak = 0
    last_date = nil
    
    dates_with_timers.each do |date|
      if last_date.nil? || date == last_date + 1.day
        temp_streak += 1
        longest_streak = [longest_streak, temp_streak].max
      else
        temp_streak = 1
      end
      last_date = date
    end
    
    # Generate calendar data for the last 3 months using efficient query
    calendar_data = {}
    timer_stats = timers
      .where(created_at: 90.days.ago.beginning_of_day..today.end_of_day)
      .group(Arel.sql("DATE(created_at)"))
      .pluck(Arel.sql("DATE(created_at), COUNT(*), SUM(duration)"))
    
    # Initialize all dates with zero values
    90.days.ago.to_date.upto(today) do |date|
      calendar_data[date.to_s] = { count: 0, duration: 0 }
    end
    
    # Fill in actual data
    timer_stats.each do |date, count, duration|
      calendar_data[date.to_s] = {
        count: count,
        duration: duration || 0
      }
    end
    
    {
      current_streak: current_streak,
      longest_streak: longest_streak,
      calendar_data: calendar_data
    }
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
    
    # Use SQL to calculate durations efficiently
    base_query = timers.by_date_range(start_date, end_date)
    
    # Calculate total time using SQL
    total_time = base_query
      .where.not(duration: nil)
      .sum(:duration)
    
    {
      total_time: total_time,
      total_tasks: base_query.count,
      weekly_breakdown: (0..3).map do |weeks_ago|
        week_start = weeks_ago.weeks.ago.beginning_of_week
        week_end = weeks_ago.weeks.ago.end_of_week
        week_timers = timers.by_date_range(week_start, week_end)
        {
          week_start: week_start,
          week_label: "Week of #{week_start.strftime('%b %d')}",
          total_duration: week_timers.where.not(duration: nil).sum(:duration),
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
