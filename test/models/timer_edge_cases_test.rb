require 'test_helper'

class TimerEdgeCasesTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "calculate_duration never returns negative values" do
    timer = @user.timers.create!(
      task_name: "Test Timer",
      status: "running",
      start_time: 1.hour.from_now  # Start time in the future (edge case)
    )
    
    # Should return 0, not negative
    assert_equal 0, timer.calculate_duration
  end

  test "pause! handles negative duration edge case" do
    timer = @user.timers.create!(
      task_name: "Test Timer",
      status: "running",
      start_time: 1.hour.from_now  # Start time in the future (edge case)
    )
    
    # Should not raise validation error
    assert_nothing_raised do
      timer.pause!
    end
    
    assert_equal "paused", timer.status
    assert_equal 0, timer.duration
  end

  test "stop! handles negative duration edge case" do
    timer = @user.timers.create!(
      task_name: "Test Timer", 
      status: "running",
      start_time: 1.hour.from_now  # Start time in the future (edge case)
    )
    
    # Should not raise validation error
    assert_nothing_raised do
      timer.stop!
    end
    
    assert_equal "stopped", timer.status
    assert_equal 0, timer.duration
  end

  test "countdown timer pause! handles edge cases" do
    timer = @user.timers.create!(
      task_name: "Countdown Test",
      status: "running",
      timer_type: "countdown",
      target_duration: 300,
      remaining_duration: 300,
      start_time: 1.hour.from_now  # Start time in the future (edge case)
    )
    
    # Should not raise validation error
    assert_nothing_raised do
      timer.pause!
    end
    
    assert_equal "paused", timer.status
    assert timer.duration >= 0
    assert timer.remaining_duration >= 0
  end
end