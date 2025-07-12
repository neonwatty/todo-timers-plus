require "test_helper"

class TimerTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @timer = timers(:running_timer)
  end

  test "should be valid" do
    assert @timer.valid?
  end

  test "task_name should be present" do
    @timer.task_name = "   "
    assert_not @timer.valid?
  end

  test "user should be present" do
    @timer.user = nil
    assert_not @timer.valid?
  end

  test "status should be present" do
    @timer.status = nil
    assert_not @timer.valid?
  end

  test "status should be valid" do
    valid_statuses = %w[pending running paused stopped completed]
    valid_statuses.each do |valid_status|
      @timer.status = valid_status
      assert @timer.valid?, "#{valid_status} should be valid"
    end
  end

  test "status should reject invalid values" do
    invalid_statuses = %w[invalid cancelled finished]
    invalid_statuses.each do |invalid_status|
      @timer.status = invalid_status
      assert_not @timer.valid?, "#{invalid_status} should be invalid"
    end
  end

  test "duration should be non-negative" do
    @timer.duration = -1
    assert_not @timer.valid?
  end

  test "should belong to user" do
    assert_respond_to @timer, :user
    assert_equal @user, @timer.user
  end

  test "should have and belong to many tags" do
    assert_respond_to @timer, :tags
  end

  test "should have and belong to many timer_tags" do
    assert_respond_to @timer, :timer_tags
  end

  test "should set default status" do
    timer = @user.timers.build(task_name: "New Timer")
    timer.save
    assert_equal "pending", timer.status
  end

  test "should parse tags string" do
    @timer.update_column(:tags, "work, project, urgent")
    parsed_tags = @timer.parse_tags
    assert_equal ["work", "project", "urgent"], parsed_tags
  end

  test "formatted_duration should return correct format" do
    @timer.duration = 3665 # 1 hour, 1 minute, 5 seconds
    assert_equal "01:01:05", @timer.formatted_duration
    
    @timer.duration = 125 # 2 minutes, 5 seconds
    assert_equal "00:02:05", @timer.formatted_duration
    
    @timer.duration = 0
    assert_equal "00:00:00", @timer.formatted_duration
  end

  test "calculate_duration should work correctly" do
    # Test completed timer
    completed = timers(:completed_timer)
    assert_equal 3600, completed.calculate_duration
    
    # Test running timer
    running = timers(:running_timer)
    running.start_time = 30.seconds.ago
    assert_in_delta 30, running.calculate_duration, 1
    
    # Test paused timer
    paused = timers(:paused_timer)
    assert_equal 1800, paused.calculate_duration
  end

  test "active scope should return running and paused timers" do
    active_timers = Timer.active
    assert_includes active_timers, timers(:running_timer)
    assert_includes active_timers, timers(:paused_timer)
    assert_not_includes active_timers, timers(:completed_timer)
    assert_not_includes active_timers, timers(:stopped_timer)
  end

  test "completed scope should return stopped and completed timers" do
    completed_timers = Timer.completed
    assert_includes completed_timers, timers(:completed_timer)
    assert_includes completed_timers, timers(:stopped_timer)
    assert_not_includes completed_timers, timers(:running_timer)
    assert_not_includes completed_timers, timers(:paused_timer)
  end

  test "by_date_range scope should filter correctly" do
    # Create timers with specific dates
    old_timer = @user.timers.create!(task_name: "Old Timer", created_at: 1.week.ago)
    recent_timer = @user.timers.create!(task_name: "Recent Timer", created_at: 1.day.ago)
    very_recent_timer = @user.timers.create!(task_name: "Very Recent Timer", created_at: 1.hour.ago)
    
    start_date = 2.days.ago
    end_date = Time.current
    
    timers_in_range = Timer.by_date_range(start_date, end_date)
    assert_not_includes timers_in_range, old_timer
    assert_includes timers_in_range, recent_timer
    assert_includes timers_in_range, very_recent_timer
  end

  test "start! should update timer correctly" do
    timer = @user.timers.create!(task_name: "New Timer", status: "pending")
    
    assert_changes -> { timer.reload.status }, from: "pending", to: "running" do
      assert_changes -> { timer.reload.start_time }, from: nil do
        timer.start!
      end
    end
  end

  test "pause! should update timer correctly" do
    timer = timers(:running_timer)
    timer.start_time = 1.minute.ago
    timer.save
    
    assert_changes -> { timer.reload.status }, from: "running", to: "paused" do
      assert_changes -> { timer.reload.duration } do
        timer.pause!
      end
    end
  end

  test "resume! should update timer correctly" do
    timer = timers(:paused_timer)
    
    assert_changes -> { timer.reload.status }, from: "paused", to: "running" do
      assert_changes -> { timer.reload.start_time } do
        timer.resume!
      end
    end
  end

  test "stop! should update timer correctly" do
    timer = timers(:running_timer)
    timer.start_time = 1.minute.ago
    timer.save
    
    assert_changes -> { timer.reload.status }, from: "running", to: "stopped" do
      assert_changes -> { timer.reload.end_time }, from: nil do
        assert_changes -> { timer.reload.duration } do
          timer.stop!
        end
      end
    end
  end

  test "should validate status transitions" do
    # Test valid transitions
    timer = @user.timers.create!(task_name: "Test Timer", status: "pending")
    assert timer.start!
    assert_equal "running", timer.status
    
    assert timer.pause!
    assert_equal "paused", timer.status
    
    assert timer.resume!
    assert_equal "running", timer.status
    
    assert timer.stop!
    assert_equal "stopped", timer.status
  end

  test "running? should return correct value" do
    assert timers(:running_timer).running?
    assert_not timers(:paused_timer).running?
    assert_not timers(:completed_timer).running?
  end

  test "paused? should return correct value" do
    assert timers(:paused_timer).paused?
    assert_not timers(:running_timer).paused?
    assert_not timers(:completed_timer).paused?
  end

  test "stopped? should return correct value" do
    assert timers(:stopped_timer).stopped?
    assert_not timers(:running_timer).stopped?
    assert_not timers(:paused_timer).stopped?
  end

  test "completed? should return correct value" do
    assert timers(:completed_timer).completed?
    assert_not timers(:running_timer).completed?
    assert_not timers(:paused_timer).completed?
  end

  test "should validate notes length" do
    timer = @user.timers.build(task_name: "Test Timer", notes: "a" * 2001)
    assert_not timer.valid?
    assert_includes timer.errors[:notes], "is too long (maximum is 2000 characters)"
  end

  test "should allow empty notes" do
    timer = @user.timers.build(task_name: "Test Timer", notes: "")
    assert timer.valid?
  end

  test "should allow nil notes" do
    timer = @user.timers.build(task_name: "Test Timer", notes: nil)
    assert timer.valid?
  end

  test "should preserve newlines in notes" do
    notes_with_newlines = "Line 1\nLine 2\nLine 3"
    timer = @user.timers.create!(task_name: "Test Timer", notes: notes_with_newlines)
    assert_equal notes_with_newlines, timer.notes
  end

  test "should handle special characters in notes" do
    special_notes = "Test with émojis 🎯 and symbols: @#$%^&*()"
    timer = @user.timers.create!(task_name: "Test Timer", notes: special_notes)
    assert_equal special_notes, timer.notes
  end
end
