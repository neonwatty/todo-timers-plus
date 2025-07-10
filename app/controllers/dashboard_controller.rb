class DashboardController < ApplicationController
  
  def index
    @active_timers = Current.user.active_timers.limit(5)
    @recent_timers = Current.user.timers.completed.limit(10)
    @total_time_today = Current.user.total_time_today
    @timer_count = Current.user.timers.count
  end
end
