require "test_helper"

class TimerDurationEditTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "should update countdown timer target duration" do
    timer = @user.timers.create!(
      task_name: "Countdown Timer",
      timer_type: "countdown",
      target_duration: 1500, # 25 minutes
      remaining_duration: 1500
    )
    
    get edit_timer_path(timer)
    assert_response :success
    
    # Update to 30 minutes
    patch timer_path(timer), params: {
      timer: {
        task_name: timer.task_name,
        duration_hours: "0",
        duration_minutes: "30",
        duration_seconds: "0"
      }
    }
    
    assert_redirected_to timer_path(timer)
    
    timer.reload
    assert_equal 1800, timer.target_duration # 30 minutes
    assert_equal 1800, timer.remaining_duration # Should update remaining too since not started
  end

  test "should update stopped stopwatch timer duration" do
    timer = @user.timers.create!(
      task_name: "Stopwatch Timer",
      timer_type: "stopwatch",
      status: "stopped",
      duration: 3600 # 1 hour
    )
    
    get edit_timer_path(timer)
    assert_response :success
    
    # Update to 1 hour 30 minutes
    patch timer_path(timer), params: {
      timer: {
        task_name: timer.task_name,
        duration_hours: "1",
        duration_minutes: "30",
        duration_seconds: "0"
      }
    }
    
    assert_redirected_to timer_path(timer)
    timer.reload
    assert_equal 5400, timer.duration # 1.5 hours
  end

  test "should not update duration for running timer" do
    timer = @user.timers.create!(
      task_name: "Running Timer",
      timer_type: "stopwatch",
      status: "running",
      start_time: 1.hour.ago,
      duration: 0
    )
    
    get edit_timer_path(timer)
    assert_response :success
    
    # Should show warning about active timer
    assert_select ".bg-amber-50", text: /Duration cannot be edited while the timer is active/
  end

  test "should handle complex duration updates" do
    timer = @user.timers.create!(
      task_name: "Complex Timer",
      timer_type: "countdown",
      target_duration: 60, # 1 minute
      remaining_duration: 60
    )
    
    # Update to 2 hours, 15 minutes, 30 seconds
    patch timer_path(timer), params: {
      timer: {
        task_name: timer.task_name,
        duration_hours: "2",
        duration_minutes: "15",
        duration_seconds: "30"
      }
    }
    
    timer.reload
    expected_duration = (2 * 3600) + (15 * 60) + 30 # 8130 seconds
    assert_equal expected_duration, timer.target_duration
  end

  test "should preserve other timer attributes when updating duration" do
    timer = @user.timers.create!(
      task_name: "Timer with tags",
      timer_type: "countdown",
      target_duration: 900,
      remaining_duration: 900,
      notes: "Important notes"
    )
    timer[:tags] = "work, focus"
    timer.save!
    
    patch timer_path(timer), params: {
      timer: {
        task_name: timer.task_name,
        duration_hours: "0",
        duration_minutes: "20",
        duration_seconds: "0",
        tags: timer[:tags],
        notes: timer.notes
      }
    }
    
    timer.reload
    assert_equal 1200, timer.target_duration # 20 minutes
    assert_equal "work, focus", timer[:tags]
    assert_equal "Important notes", timer.notes
  end

  test "should not update remaining duration for started countdown timer" do
    timer = @user.timers.create!(
      task_name: "Started Countdown",
      timer_type: "countdown",
      status: "paused",
      target_duration: 1500,
      remaining_duration: 1000, # Already used 500 seconds
      start_time: 10.minutes.ago
    )
    
    # Try to update duration - should not change remaining
    patch timer_path(timer), params: {
      timer: {
        task_name: timer.task_name,
        duration_hours: "0",
        duration_minutes: "30",
        duration_seconds: "0"
      }
    }
    
    timer.reload
    assert_equal 1800, timer.target_duration # Updated to 30 minutes
    assert_equal 1000, timer.remaining_duration # Should stay the same
  end
end