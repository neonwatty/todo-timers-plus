require "test_helper"

class TimerTypeSwitchingTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    post session_url, params: { 
      email_address: @user.email_address, 
      password: "password" 
    }
    follow_redirect!
  end

  test "create stopwatch timer by default" do
    post timers_path, params: {
      timer: {
        task_name: "Default Timer",
        tags: "test"
      }
    }
    
    timer = Timer.last
    assert_equal "stopwatch", timer.timer_type
    assert timer.stopwatch?
    assert_not timer.countdown?
    assert_nil timer.target_duration
    assert_nil timer.remaining_duration
  end

  test "create countdown timer with explicit type" do
    post timers_path, params: {
      timer: {
        task_name: "Countdown Timer",
        timer_type: "countdown",
        duration_hours: "1",
        duration_minutes: "30",
        duration_seconds: "0"
      }
    }
    
    timer = Timer.last
    assert_equal "countdown", timer.timer_type
    assert timer.countdown?
    assert_not timer.stopwatch?
    assert_equal 5400, timer.target_duration # 1.5 hours in seconds
    assert_equal 5400, timer.remaining_duration
  end

  test "timer type affects behavior" do
    # Create both types of timers
    stopwatch = @user.timers.create!(
      task_name: "Stopwatch",
      timer_type: "stopwatch",
      status: "stopped"
    )
    
    countdown = @user.timers.create!(
      task_name: "Countdown",
      timer_type: "countdown",
      target_duration: 300,
      remaining_duration: 300,
      status: "stopped"
    )
    
    # Start both timers
    patch start_timer_path(stopwatch)
    patch start_timer_path(countdown)
    
    # Check behavior after 30 seconds
    travel 30.seconds do
      stopwatch.reload
      countdown.reload
      
      # Stopwatch counts up
      assert_in_delta 30, stopwatch.calculate_duration, 1
      assert_match /00:00:(29|30)/, stopwatch.formatted_duration  # Allow for timing variance
      assert_equal 0, stopwatch.calculate_remaining_time
      assert_not stopwatch.expired?
      
      # Countdown counts down
      assert_in_delta 270, countdown.calculate_remaining_time, 1
      assert_match /00:04:(29|30|31)/, countdown.formatted_duration  # Allow for timing variance
      assert_in_delta 10, countdown.progress_percentage.round, 1
      assert_not countdown.expired?
    end
  end

  test "timer type persists through state changes" do
    timer = @user.timers.create!(
      task_name: "Type Test",
      timer_type: "countdown",
      target_duration: 600,
      remaining_duration: 600,
      status: "stopped"
    )
    
    # Start
    patch start_timer_path(timer)
    timer.reload
    assert_equal "countdown", timer.timer_type
    
    # Pause
    patch pause_timer_path(timer)
    timer.reload
    assert_equal "countdown", timer.timer_type
    
    # Resume
    patch resume_timer_path(timer)
    timer.reload
    assert_equal "countdown", timer.timer_type
    
    # Stop
    patch stop_timer_path(timer)
    timer.reload
    assert_equal "countdown", timer.timer_type
    
    # Reset
    patch reset_timer_path(timer)
    timer.reload
    assert_equal "countdown", timer.timer_type
  end

  test "edit view shows correct timer type" do
    timer = @user.timers.create!(
      task_name: "Edit Test",
      timer_type: "countdown",
      target_duration: 1800,
      remaining_duration: 1800,
      status: "stopped"
    )
    
    get edit_timer_path(timer)
    assert_response :success
    
    # Should show timer type info
    assert_select ".bg-blue-50 p", /Countdown Timer/
    assert_select "p", /Target duration: 00:30:00/
  end

  test "timer list shows both timer types correctly" do
    # Create multiple timers
    @user.timers.create!(
      task_name: "Morning Standup",
      timer_type: "stopwatch",
      duration: 900,
      status: "completed"
    )
    
    @user.timers.create!(
      task_name: "Focus Session",
      timer_type: "countdown",
      target_duration: 1500,
      remaining_duration: 0,
      status: "expired"
    )
    
    get timers_path
    assert_response :success
    
    # Check stopwatch timer display
    assert_select "a", text: "Morning Standup"
    assert_select ".font-mono", text: "00:15:00"
    
    # Check countdown timer display
    assert_select "a", text: "Focus Session"
    assert_select ".bg-blue-100.text-blue-800", text: /Countdown/
    assert_select ".bg-red-100.text-red-800", text: /Expired/
  end

  test "analytics handles both timer types" do
    # Create completed timers of both types
    @user.timers.create!(
      task_name: "Stopwatch Task",
      timer_type: "stopwatch",
      duration: 3600,
      status: "completed",
      created_at: Time.current
    )
    
    @user.timers.create!(
      task_name: "Countdown Task",
      timer_type: "countdown",
      target_duration: 1800,
      remaining_duration: 0,
      duration: 1800,
      status: "completed",
      completed_at: Time.current,
      created_at: Time.current
    )
    
    get analytics_path
    assert_response :success
    
    # Both timer types should contribute to analytics
    assert_select "h1", text: "Analytics"  # Verify we're on analytics page
    assert_match /Stopwatch Task/, response.body
    assert_match /Countdown Task/, response.body
  end
end