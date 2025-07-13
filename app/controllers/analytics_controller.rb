class AnalyticsController < ApplicationController
  
  def index
    @period = params[:period] || 'week'
    @analytics = Current.user.analytics_data(@period.to_sym)
    
    # Dashboard stats (moved from dashboard controller)
    @active_timers = Current.user.active_timers
    @recent_timers = Current.user.timers.completed.order(updated_at: :desc).limit(10)
    @total_time_today = Current.user.total_time_today
    @timer_count = Current.user.timers.count
    @active_timer_count = @active_timers.count
    
    # Prepare chart data
    @time_chart_data = prepare_time_chart_data
    @task_chart_data = prepare_task_chart_data
    @tag_chart_data = prepare_tag_chart_data
    
    # Calculate streaks
    @streak_data = Current.user.calculate_streak_data
    @current_streak = @streak_data[:current_streak]
    @longest_streak = @streak_data[:longest_streak]
    
    # Calculate productivity score
    @productivity_score = calculate_productivity_score
    
    respond_to do |format|
      format.html
      format.json { render json: @analytics }
    end
  end
  
  private
  
  def prepare_time_chart_data
    case @period
    when 'day'
      {
        labels: @analytics[:hourly_breakdown].map { |h| h[:label] },
        data: @analytics[:hourly_breakdown].map { |h| h[:total_duration] }
      }
    when 'week'
      {
        labels: @analytics[:daily_breakdown].map { |d| d[:day_name] },
        data: @analytics[:daily_breakdown].map { |d| d[:total_duration] }
      }
    else # month
      {
        labels: @analytics[:weekly_breakdown].map { |w| w[:week_label] },
        data: @analytics[:weekly_breakdown].map { |w| w[:total_duration] }
      }
    end
  end
  
  def prepare_task_chart_data
    return { labels: [], data: [] } unless @analytics[:top_tasks].present?
    
    {
      labels: @analytics[:top_tasks].map { |task, _| task },
      data: @analytics[:top_tasks].map { |_, duration| duration }
    }
  end
  
  def prepare_tag_chart_data
    tag_analytics = Current.user.tag_analytics(@period)
    {
      labels: tag_analytics.map { |tag| tag[:name] },
      data: tag_analytics.map { |tag| tag[:duration] }
    }
  end
  
  def calculate_productivity_score
    total_hours = @analytics[:total_time] / 3600.0
    # Base score from hours worked (max 100 points)
    time_score = [total_hours * 10, 100].min
    # Streak bonus (max 50 points)
    streak_bonus = [@current_streak * 5, 50].min
    # Consistency bonus based on active days
    active_days = case @period
    when 'day'
      @analytics[:hourly_breakdown].count { |h| h[:task_count] > 0 }
    when 'week'  
      @analytics[:daily_breakdown].count { |d| d[:task_count] > 0 }
    else
      @analytics[:weekly_breakdown].count { |w| w[:task_count] > 0 }
    end
    consistency_bonus = active_days * 10
    
    [(time_score + streak_bonus + consistency_bonus).round, 200].min
  end
end
