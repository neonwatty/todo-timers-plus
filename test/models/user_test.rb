require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "email should be present" do
    @user.email_address = "   "
    assert_not @user.valid?
  end

  test "email should be unique" do
    duplicate_user = @user.dup
    duplicate_user.email_address = @user.email_address.upcase
    @user.save
    assert_not duplicate_user.valid?
  end

  test "email should be saved as lowercase" do
    mixed_case_email = "Foo@ExAMPle.CoM"
    @user.email_address = mixed_case_email
    @user.save
    assert_equal mixed_case_email.downcase, @user.reload.email_address
  end

  test "email validation should accept valid addresses" do
    valid_addresses = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org
                        first.last@foo.jp alice+bob@baz.cn]
    valid_addresses.each do |valid_address|
      @user.email_address = valid_address
      assert @user.valid?, "#{valid_address.inspect} should be valid"
    end
  end

  test "email validation should reject invalid addresses" do
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
                          foo@bar_baz.com foo@bar+baz.com]
    invalid_addresses.each do |invalid_address|
      @user.email_address = invalid_address
      assert_not @user.valid?, "#{invalid_address.inspect} should be invalid"
    end
  end

  test "should have many timers" do
    assert_respond_to @user, :timers
  end

  test "should have many tags through timers" do
    assert_respond_to @user, :tags
  end

  test "timers should be destroyed when user is destroyed" do
    @user.save
    timer = @user.timers.create!(task_name: "Test Timer")
    timer_count = @user.timers.count
    assert_difference 'Timer.count', -timer_count do
      @user.destroy
    end
  end

  test "should calculate total time tracked" do
    @user.save
    # Clear existing timers from fixtures
    @user.timers.destroy_all
    
    timer1 = @user.timers.create!(task_name: "Timer 1", duration: 3600)
    timer2 = @user.timers.create!(task_name: "Timer 2", duration: 1800)
    
    assert_equal 5400, @user.total_time_tracked
  end

  test "should calculate timer stats" do
    @user.save
    # Clear existing timers from fixtures
    @user.timers.destroy_all
    
    @user.timers.create!(task_name: "Timer 1", duration: 3600, status: 'completed')
    @user.timers.create!(task_name: "Timer 2", duration: 1800, status: 'running')
    @user.timers.create!(task_name: "Timer 3", duration: 900, status: 'paused')
    
    stats = @user.timer_stats
    assert_equal 3, stats[:total_timers]
    assert_equal 2, stats[:active_timers] # running + paused
    assert_equal 1, stats[:completed_timers]
    assert_equal 6300, stats[:total_duration]
  end

  test "should get timers by date range" do
    @user.save
    old_timer = @user.timers.create!(task_name: "Old Timer", created_at: 2.months.ago)
    recent_timer = @user.timers.create!(task_name: "Recent Timer", created_at: 1.day.ago)
    
    timers = @user.timers_by_date_range(1.week.ago, Time.current)
    assert_includes timers, recent_timer
    assert_not_includes timers, old_timer
  end

  test "should return analytics data for week" do
    @user.save
    timer = @user.timers.create!(
      task_name: "Test Timer",
      duration: 3600,
      created_at: 1.day.ago,
      status: 'completed'
    )
    
    analytics = @user.analytics_data(:week)
    assert analytics[:total_time] > 0
    assert analytics[:total_tasks] > 0
    assert analytics[:daily_breakdown].is_a?(Array)
    assert analytics[:top_tasks].is_a?(Array)
  end

  test "should return analytics data for month" do
    @user.save
    timer = @user.timers.create!(
      task_name: "Test Timer",
      duration: 3600,
      created_at: 1.week.ago,
      status: 'completed'
    )
    
    analytics = @user.analytics_data(:month)
    assert analytics[:total_time] > 0
    assert analytics[:total_tasks] > 0
    assert analytics[:weekly_breakdown].is_a?(Array)
    assert analytics[:top_tasks].is_a?(Array)
  end

  test "should return analytics data for day" do
    @user.save
    timer = @user.timers.create!(
      task_name: "Test Timer",
      duration: 3600,
      created_at: 2.hours.ago,
      status: 'completed'
    )
    
    analytics = @user.analytics_data(:day)
    assert analytics[:total_time] > 0
    assert analytics[:total_tasks] > 0
    assert analytics[:hourly_breakdown].is_a?(Array)
    assert_equal 24, analytics[:hourly_breakdown].length
  end
end
