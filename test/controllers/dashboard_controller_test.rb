require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "should get index when authenticated" do
    get dashboard_url
    assert_response :success
    assert_select "h1", "Dashboard"
  end

  test "should show active timers" do
    get dashboard_url
    assert_response :success
    
    # Check for active timers section
    assert_match /Active Timers/, response.body
    # Note: The view shows all timers in multiple sections, not just active ones
    assert_select "[data-timer-id]"
  end

  test "should show timer stats" do
    get dashboard_url
    assert_response :success
    
    # Check for stats sections
    assert_match /Active Timers/, response.body
    assert_match /Total Timers/, response.body
    assert_match /Today's Time/, response.body
  end

  test "should show recent timers" do
    get dashboard_url
    assert_response :success
    
    # Check for recent activity section
    assert_select "h2", text: "Recent Activity"
  end

  test "should show quick actions" do
    get dashboard_url
    assert_response :success
    
    # Check for quick action buttons
    assert_select "a[href=?]", new_timer_path
    assert_select "a[href=?]", timers_path
    assert_select "a[href=?]", analytics_path
  end

  test "should calculate today's time correctly" do
    # Create a timer for today
    @user.timers.create!(
      task_name: "Today's Timer",
      duration: 3600,
      status: "completed",
      created_at: Time.current
    )
    
    get dashboard_url
    assert_response :success
    
    # Should show today's time
    assert_match /1h 0m/, response.body
  end

  test "should redirect to login when not authenticated" do
    sign_out
    
    get dashboard_url
    assert_redirected_to new_session_url
  end

  test "dashboard should be root path when authenticated" do
    get root_url
    assert_response :success
    assert_select "h1", "Dashboard"
  end

end