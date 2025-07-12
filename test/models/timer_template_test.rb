require "test_helper"

class TimerTemplateTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @template = timer_templates(:one)
  end

  test "should be valid" do
    assert @template.valid?
  end

  test "should require name" do
    @template.name = nil
    assert_not @template.valid?
    assert_includes @template.errors[:name], "can't be blank"
  end

  test "should require user" do
    @template.user = nil
    assert_not @template.valid?
    assert_includes @template.errors[:user], "must exist"
  end

  test "should set default timer_type when nil" do
    @template.timer_type = nil
    @template.valid? # This triggers the before_validation callback
    assert_equal "stopwatch", @template.timer_type
  end

  test "should accept valid timer types" do
    @template.timer_type = "stopwatch"
    assert @template.valid?
    
    @template.timer_type = "countdown"
    assert @template.valid?
  end

  test "should reject invalid timer types" do
    @template.timer_type = "invalid"
    assert_not @template.valid?
    assert_includes @template.errors[:timer_type], "is not included in the list"
  end

  test "should require target_duration for countdown timers" do
    @template.timer_type = "countdown"
    @template.target_duration = nil
    assert_not @template.valid?
    assert_includes @template.errors[:target_duration], "can't be blank"
  end

  test "should require positive target_duration for countdown timers" do
    @template.timer_type = "countdown"
    @template.target_duration = 0
    assert_not @template.valid?
    assert_includes @template.errors[:target_duration], "must be greater than 0"
  end

  test "should not require target_duration for stopwatch timers" do
    @template.timer_type = "stopwatch"
    @template.target_duration = nil
    assert @template.valid?
  end

  test "should validate uniqueness of name per user" do
    duplicate = @user.timer_templates.build(
      name: @template.name,
      timer_type: "stopwatch"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "should allow same name for different users" do
    other_user = users(:two)
    duplicate = other_user.timer_templates.build(
      name: @template.name,
      timer_type: "stopwatch"
    )
    assert duplicate.valid?
  end

  test "countdown? should return true for countdown timers" do
    @template.timer_type = "countdown"
    assert @template.countdown?
  end

  test "countdown? should return false for stopwatch timers" do
    @template.timer_type = "stopwatch"
    assert_not @template.countdown?
  end

  test "stopwatch? should return true for stopwatch timers" do
    @template.timer_type = "stopwatch"
    assert @template.stopwatch?
  end

  test "stopwatch? should return false for countdown timers" do
    @template.timer_type = "countdown"
    assert_not @template.stopwatch?
  end

  test "parse_tags should split comma-separated tags" do
    @template.tags = "work, focus, pomodoro"
    expected = ["work", "focus", "pomodoro"]
    assert_equal expected, @template.parse_tags
  end

  test "parse_tags should handle empty tags" do
    @template.tags = nil
    assert_equal [], @template.parse_tags
    
    @template.tags = ""
    assert_equal [], @template.parse_tags
  end

  test "parse_tags should strip whitespace" do
    @template.tags = " work ,  focus  , pomodoro "
    expected = ["work", "focus", "pomodoro"]
    assert_equal expected, @template.parse_tags
  end

  test "formatted_duration should format countdown duration" do
    @template.timer_type = "countdown"
    @template.target_duration = 1500 # 25 minutes
    assert_equal "00:25:00", @template.formatted_duration
  end

  test "formatted_duration should handle hours" do
    @template.timer_type = "countdown"
    @template.target_duration = 3661 # 1 hour, 1 minute, 1 second
    assert_equal "01:01:01", @template.formatted_duration
  end

  test "formatted_duration should return dash for stopwatch" do
    @template.timer_type = "stopwatch"
    assert_equal "—", @template.formatted_duration
  end

  test "formatted_duration should return dash for countdown without duration" do
    @template.timer_type = "countdown"
    @template.target_duration = nil
    assert_equal "—", @template.formatted_duration
  end

  test "should initialize with default values" do
    template = TimerTemplate.new
    assert_equal 0, template.usage_count
    assert_nil template.last_used_at
  end

  test "create_timer_for_user should create timer with template attributes" do
    timer = @template.create_timer_for_user(@user)
    
    assert timer.persisted?
    assert_equal @user, timer.user
    assert_equal @template.task_name, timer.task_name
    assert_equal @template.timer_type, timer.timer_type
    assert_equal "stopped", timer.status
  end

  test "create_timer_for_user should set target_duration for countdown timers" do
    @template.timer_type = "countdown"
    @template.target_duration = 1500
    
    timer = @template.create_timer_for_user(@user)
    
    assert_equal 1500, timer.target_duration
    assert_equal 1500, timer.remaining_duration
  end

  test "create_timer_for_user should allow overrides" do
    overrides = { task_name: "Custom Task" }
    timer = @template.create_timer_for_user(@user, overrides)
    
    assert_equal "Custom Task", timer.task_name
  end

  test "create_timer_for_user should increment usage_count and update last_used_at" do
    original_count = @template.usage_count
    original_time = @template.last_used_at
    
    timer = @template.create_timer_for_user(@user)
    @template.reload
    
    assert_equal original_count + 1, @template.usage_count
    assert @template.last_used_at > original_time
  end

  test "popular scope should order by usage_count desc" do
    template1 = @user.timer_templates.create!(name: "Low Usage", timer_type: "stopwatch", usage_count: 1)
    template2 = @user.timer_templates.create!(name: "High Usage", timer_type: "stopwatch", usage_count: 10)
    
    popular_templates = @user.timer_templates.popular
    assert_equal template2, popular_templates.first
  end

  test "recently_used scope should order by last_used_at desc" do
    template1 = @user.timer_templates.create!(name: "Old", timer_type: "stopwatch", last_used_at: 1.week.ago)
    template2 = @user.timer_templates.create!(name: "Recent", timer_type: "stopwatch", last_used_at: 1.day.ago)
    
    recent_templates = @user.timer_templates.recently_used
    assert_equal template2, recent_templates.first
  end

  test "by_type scope should filter by timer_type" do
    countdown_template = @user.timer_templates.create!(
      name: "Countdown Test", 
      timer_type: "countdown", 
      target_duration: 1500
    )
    stopwatch_template = @user.timer_templates.create!(
      name: "Stopwatch Test", 
      timer_type: "stopwatch"
    )
    
    countdown_results = @user.timer_templates.by_type("countdown")
    stopwatch_results = @user.timer_templates.by_type("stopwatch")
    
    assert_includes countdown_results, countdown_template
    assert_not_includes countdown_results, stopwatch_template
    assert_includes stopwatch_results, stopwatch_template
    assert_not_includes stopwatch_results, countdown_template
  end
end
