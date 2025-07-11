require "test_helper"

class TimerCountdownTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "countdown timer attributes" do
    timer = @user.timers.create!(
      task_name: "Test Countdown",
      timer_type: "countdown",
      target_duration: 1500,
      remaining_duration: 1500
    )
    
    assert timer.valid?
    assert timer.countdown?
    assert_not timer.stopwatch?
    assert_equal 1500, timer.target_duration
    assert_equal 1500, timer.remaining_duration
  end

  test "calculate_remaining_time for stopped countdown" do
    timer = @user.timers.create!(
      task_name: "Stopped Countdown",
      timer_type: "countdown",
      target_duration: 600,
      remaining_duration: 600,
      status: "stopped"
    )
    
    assert_equal 600, timer.calculate_remaining_time
  end

  test "calculate_remaining_time for running countdown" do
    timer = @user.timers.create!(
      task_name: "Running Countdown",
      timer_type: "countdown",
      target_duration: 300,
      remaining_duration: 300,
      status: "running",
      start_time: 30.seconds.ago
    )
    
    remaining = timer.calculate_remaining_time
    assert_in_delta 270, remaining, 1 # Allow 1 second variance
  end

  test "calculate_remaining_time for paused countdown" do
    timer = @user.timers.create!(
      task_name: "Paused Countdown",
      timer_type: "countdown",
      target_duration: 1000,
      remaining_duration: 750,
      status: "paused"
    )
    
    assert_equal 750, timer.calculate_remaining_time
  end

  test "calculate_remaining_time for expired countdown" do
    timer = @user.timers.create!(
      task_name: "Expired Countdown",
      timer_type: "countdown",
      target_duration: 60,
      remaining_duration: 60,
      status: "expired"
    )
    
    assert_equal 0, timer.calculate_remaining_time
  end

  test "calculate_remaining_time prevents negative values" do
    timer = @user.timers.create!(
      task_name: "Overrun Countdown",
      timer_type: "countdown",
      target_duration: 10,
      remaining_duration: 10,
      status: "running",
      start_time: 20.seconds.ago
    )
    
    assert_equal 0, timer.calculate_remaining_time
  end

  test "progress_percentage calculations" do
    timer = @user.timers.create!(
      task_name: "Progress Test",
      timer_type: "countdown",
      target_duration: 100,
      remaining_duration: 100,
      status: "stopped"
    )
    
    # Full time remaining (not started)
    assert_equal 0.0, timer.progress_percentage
    
    # Paused with half time remaining
    timer.update!(status: "paused", remaining_duration: 50)
    assert_equal 50.0, timer.progress_percentage
    
    # Paused with quarter time remaining
    timer.update!(status: "paused", remaining_duration: 25)
    assert_equal 75.0, timer.progress_percentage
    
    # Expired (no time remaining)
    timer.update!(status: "expired", remaining_duration: 0)
    assert_equal 100.0, timer.progress_percentage
  end

  test "expired? method" do
    timer = @user.timers.create!(
      task_name: "Expiry Test",
      timer_type: "countdown",
      target_duration: 60,
      remaining_duration: 60
    )
    
    # Not expired when stopped
    assert_not timer.expired?
    
    # Not expired when running with time left
    timer.update!(status: "running", start_time: 30.seconds.ago)
    assert_not timer.expired?
    
    # Expired when status is expired
    timer.update!(status: "expired")
    assert timer.expired?
    
    # Expired when running past target duration
    timer.update!(status: "running", start_time: 90.seconds.ago)
    assert timer.expired?
  end

  test "formatted_duration for countdown timers" do
    timer = @user.timers.create!(
      task_name: "Format Test",
      timer_type: "countdown",
      target_duration: 3665, # 1:01:05
      remaining_duration: 3665,
      status: "stopped"
    )
    
    assert_equal "01:01:05", timer.formatted_duration
    
    # When running
    timer.update!(status: "running", start_time: 65.seconds.ago)
    assert_equal "01:00:00", timer.formatted_duration
    
    # When paused
    timer.update!(status: "paused", remaining_duration: 125)
    assert_equal "00:02:05", timer.formatted_duration
  end

  test "stopwatch timer remaining time always zero" do
    timer = @user.timers.create!(
      task_name: "Stopwatch Test",
      timer_type: "stopwatch",
      status: "running",
      start_time: 2.minutes.ago
    )
    
    assert_equal 0, timer.calculate_remaining_time
    assert_equal 0.0, timer.progress_percentage
    assert_not timer.expired?
  end

  test "timer state transitions" do
    timer = @user.timers.create!(
      task_name: "State Test",
      timer_type: "countdown",
      target_duration: 300,
      remaining_duration: 300,
      status: "stopped"
    )
    
    # Start
    timer.start!
    assert_equal "running", timer.status
    assert_not_nil timer.start_time
    
    # Pause after some time
    travel 10.seconds do
      timer.pause!
      assert_equal "paused", timer.status
      assert_in_delta 290, timer.remaining_duration, 1
    end
    
    # Resume
    saved_remaining = timer.remaining_duration
    timer.resume!
    assert_equal "running", timer.status
    assert_equal saved_remaining, timer.remaining_duration
    
    # Stop
    timer.stop!
    assert_equal "stopped", timer.status
    assert_not_nil timer.end_time
  end
end