require "test_helper"

class CountdownTimerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    post session_url, params: { 
      email_address: @user.email_address, 
      password: "password" 
    }
    follow_redirect!
  end

  test "create countdown timer with duration" do
    get new_timer_path
    assert_response :success
    
    # Create a 25-minute countdown timer
    assert_difference "Timer.count", 1 do
      post timers_path, params: {
        timer: {
          task_name: "Pomodoro Session",
          timer_type: "countdown",
          duration_hours: "0",
          duration_minutes: "25",
          duration_seconds: "0",
          tags: "work, focus"
        }
      }
    end
    
    timer = Timer.last
    assert_redirected_to timer_path(timer)
    follow_redirect!
    
    # Verify countdown timer attributes
    assert_equal "Pomodoro Session", timer.task_name
    assert_equal "countdown", timer.timer_type
    assert_equal 1500, timer.target_duration # 25 minutes in seconds
    assert_equal 1500, timer.remaining_duration
    assert_equal "stopped", timer.status
    assert timer.countdown?
    assert_not timer.stopwatch?
  end

  test "countdown timer counts down when running" do
    # Create a 5-minute countdown timer
    timer = @user.timers.create!(
      task_name: "Quick Timer",
      timer_type: "countdown",
      target_duration: 300,
      remaining_duration: 300,
      status: "stopped"
    )
    
    # Start the timer
    patch start_timer_path(timer)
    timer.reload
    
    assert_equal "running", timer.status
    assert_not_nil timer.start_time
    
    # Simulate time passing
    travel 30.seconds do
      remaining = timer.calculate_remaining_time
      assert_in_delta 270, remaining, 1 # 300 - 30 seconds (allow 1 second variance)
      assert_in_delta 10, timer.progress_percentage.round, 1 # (30/300) * 100
    end
    
    # Pause the timer
    travel 60.seconds do
      patch pause_timer_path(timer)
      timer.reload
      
      assert_equal "paused", timer.status
      assert_in_delta 240, timer.remaining_duration, 1 # 300 - 60 seconds
      assert_in_delta 20, timer.progress_percentage.round, 1
    end
  end

  test "countdown timer expiration" do
    # Create a 10-second countdown timer
    timer = @user.timers.create!(
      task_name: "Short Timer",
      timer_type: "countdown",
      target_duration: 10,
      remaining_duration: 10,
      status: "stopped"
    )
    
    # Start the timer
    patch start_timer_path(timer)
    timer.reload
    
    # Let it expire
    travel 15.seconds do
      remaining = timer.calculate_remaining_time
      assert_equal 0, remaining
      assert timer.expired?
      assert_equal 100, timer.progress_percentage
    end
  end

  test "reset countdown timer" do
    # Create a partially used countdown timer
    timer = @user.timers.create!(
      task_name: "Reset Test Timer",
      timer_type: "countdown",
      target_duration: 600,
      remaining_duration: 300, # Half used
      status: "paused"
    )
    
    # Reset the timer
    patch reset_timer_path(timer)
    timer.reload
    
    assert_equal "stopped", timer.status
    assert_equal timer.target_duration, timer.remaining_duration
    assert_nil timer.start_time
    assert_nil timer.end_time
    assert_not timer.expired?
  end

  test "countdown timer with JSON response" do
    timer = @user.timers.create!(
      task_name: "API Test Timer",
      timer_type: "countdown",
      target_duration: 1800,
      remaining_duration: 1800,
      status: "stopped"
    )
    
    # Start timer with JSON format
    patch start_timer_path(timer), headers: { "Accept" => "application/json" }
    assert_response :success
    
    json = JSON.parse(response.body)
    assert_equal "running", json["status"]
    assert_equal "countdown", json["timer_type"]
    assert_equal 1800, json["target_duration"]
    assert json["is_countdown"]
  end

  test "cannot create countdown timer without duration" do
    post timers_path, params: {
      timer: {
        task_name: "No Duration Timer",
        timer_type: "countdown",
        duration_hours: "0",
        duration_minutes: "0",
        duration_seconds: "0"
      }
    }
    
    assert_response :unprocessable_entity
    assert_match /Please set a duration for the countdown timer/, response.body
  end

  test "stopwatch timer behavior remains unchanged" do
    # Create a stopwatch timer
    timer = @user.timers.create!(
      task_name: "Stopwatch Timer",
      timer_type: "stopwatch",
      status: "stopped"
    )
    
    assert timer.stopwatch?
    assert_not timer.countdown?
    assert_nil timer.target_duration
    assert_nil timer.remaining_duration
    
    # Start and verify it counts up
    patch start_timer_path(timer)
    timer.reload
    
    travel 30.seconds do
      assert_in_delta 30, timer.calculate_duration, 1
      assert_equal 0, timer.calculate_remaining_time # Stopwatch always returns 0
    end
  end

  test "timer display shows correct format for countdown" do
    timer = @user.timers.create!(
      task_name: "Display Test",
      timer_type: "countdown",
      target_duration: 3665, # 1 hour, 1 minute, 5 seconds
      remaining_duration: 3665,
      status: "stopped"
    )
    
    get timer_path(timer)
    assert_response :success
    
    # Check for countdown-specific UI elements
    assert_select "[data-countdown-timer-is-countdown-value='true']"
    assert_select "[data-countdown-timer-target-duration-value='3665']"
    assert_select ".bg-blue-100.text-blue-800", /Countdown Timer/
    assert_select "button[data-action='click->countdown-timer#start']", /Start Timer/
  end
end