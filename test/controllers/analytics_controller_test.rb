require "test_helper"

class AnalyticsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
    
    # Create some timers for analytics
    @user.timers.create!(
      task_name: "Analytics Test Timer 1",
      duration: 3600,
      status: "completed",
      created_at: 1.day.ago
    )
    
    @user.timers.create!(
      task_name: "Analytics Test Timer 2",
      duration: 1800,
      status: "completed",
      created_at: 2.days.ago
    )
  end

  test "should get index when authenticated" do
    get analytics_url
    assert_response :success
    assert_select "h1", "Analytics"
  end

  test "should show analytics for week by default" do
    get analytics_url
    assert_response :success
    
    # Check for period selector
    assert_select "a", text: "This Week"
    
    # Check for stats sections
    assert_match /Total Time/, response.body
    assert_match /Total Tasks/, response.body
    assert_match /Avg per Task/, response.body
    assert_match /Most Productive/, response.body
    
    # Check for charts
    assert_select "#timeChart"
    assert_select "#tasksChart"
  end

  test "should show analytics for day period" do
    get analytics_url, params: { period: "day" }
    assert_response :success
    
    # Should show hourly breakdown
    assert_match /hourly_breakdown/, response.body
  end

  test "should show analytics for month period" do
    get analytics_url, params: { period: "month" }
    assert_response :success
    
    # Should show weekly breakdown
    assert_match /weekly_breakdown/, response.body
  end

  test "should calculate total time correctly" do
    get analytics_url
    assert_response :success
    
    # Should show total time
    assert_match /Total Time/, response.body
  end

  test "should show top tasks" do
    get analytics_url
    assert_response :success
    
    # Should have tasks chart data
    assert_match /Analytics Test Timer/, response.body
  end

  test "should show detailed breakdown" do
    get analytics_url
    assert_response :success
    
    # Check for detailed breakdown section
    assert_select "h3", text: "Detailed Breakdown"
  end

  test "should have action buttons" do
    get analytics_url
    assert_response :success
    
    # Check for action buttons
    assert_select "a[href=?]", timers_path
    assert_select "a[href=?]", new_timer_path
  end

  test "should require authentication" do
    sign_out
    
    get analytics_url
    assert_redirected_to new_session_url
  end

  test "should handle empty analytics gracefully" do
    # Clear all timers
    @user.timers.destroy_all
    
    get analytics_url
    assert_response :success
    
    # Should still show the page without errors
    assert_select "h1", "Analytics"
    assert_match /0h 0m/, response.body
  end

end