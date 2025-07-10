require "test_helper"

class TimerBasicTest < ActionDispatch::IntegrationTest
  test "basic authentication and timer access" do
    user = users(:one)
    
    # Step 1: Try accessing timers without authentication - should redirect
    get timers_path
    assert_redirected_to new_session_path
    
    # Step 2: Sign in
    post session_url, params: { 
      email_address: user.email_address, 
      password: "password" 
    }
    # Should redirect to the originally requested URL (timers_path)
    assert_redirected_to timers_path
    follow_redirect!
    
    # Step 3: Now try accessing timers - should work
    get timers_path
    assert_response :success
    assert_match user.email_address, response.body
    
    # Step 4: Create a timer using the existing user
    initial_count = Timer.count
    post timers_path, params: {
      timer: {
        task_name: "Basic test timer"
      }
    }
    
    # Should succeed and create timer
    assert_equal initial_count + 1, Timer.count
    timer = Timer.last
    assert_equal "Basic test timer", timer.task_name
    assert_equal user.id, timer.user_id
  end
end