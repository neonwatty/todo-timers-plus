require "test_helper"

class TimerCompleteWorkflowTest < ActionDispatch::IntegrationTest
  test "complete timer workflow from creation to completion" do
    user = users(:one)
    
    # Authenticate first
    post session_url, params: { 
      email_address: user.email_address, 
      password: "password" 
    }
    follow_redirect!
    
    # Test 1: Create a new timer
    get new_timer_path
    assert_response :success
    assert_select "form[action='#{timers_path}']"
    
    assert_difference "Timer.count", 1 do
      post timers_path, params: {
        timer: {
          task_name: "Complete workflow test",
          tags: "integration, testing"
        }
      }
    end
    
    timer = Timer.last
    assert_redirected_to timer_path(timer)
    follow_redirect!
    
    assert_equal "Complete workflow test", timer.task_name
    assert_equal "integration, testing", timer[:tags]
    assert_equal "stopped", timer.status
    assert_equal user.id, timer.user_id
    
    # Test 2: Start the timer
    patch start_timer_path(timer)
    assert_redirected_to timers_path
    follow_redirect!
    
    timer.reload
    assert_equal "running", timer.status
    assert_not_nil timer.start_time
    assert_nil timer.end_time
    assert_match /Timer started!/, flash[:notice]
    
    # Test 3: Pause the timer
    travel 30.seconds do
      patch pause_timer_path(timer)
      assert_redirected_to timers_path
      follow_redirect!
      
      timer.reload
      assert_equal "paused", timer.status
      assert timer.duration > 0
      assert_not_nil timer.end_time
      assert_match /Timer paused!/, flash[:notice]
    end
    
    # Test 4: Resume the timer
    patch resume_timer_path(timer)
    assert_redirected_to timers_path
    follow_redirect!
    
    timer.reload
    assert_equal "running", timer.status
    assert_not_nil timer.start_time
    assert_nil timer.end_time
    assert_match /Timer resumed!/, flash[:notice]
    
    # Test 5: Stop the timer
    travel 45.seconds do
      patch stop_timer_path(timer)
      assert_redirected_to timers_path
      follow_redirect!
      
      timer.reload
      assert_equal "stopped", timer.status
      assert timer.duration > 0
      assert_not_nil timer.end_time
      assert_match /Timer stopped!/, flash[:notice]
    end
    
    # Test 6: Edit the timer
    get edit_timer_path(timer)
    assert_response :success
    assert_select "form[action='#{timer_path(timer)}']"
    
    patch timer_path(timer), params: {
      timer: {
        task_name: "Updated workflow test",
        tags: "updated, testing"
      }
    }
    
    assert_redirected_to timer_path(timer)
    follow_redirect!
    
    timer.reload
    assert_equal "Updated workflow test", timer.task_name
    assert_equal "updated, testing", timer[:tags]
    assert_match /successfully updated/, flash[:notice]
    
    # Test 7: Delete the timer
    assert_difference "Timer.count", -1 do
      delete timer_path(timer)
    end
    
    assert_redirected_to timers_path
    follow_redirect!
    assert_match /successfully deleted/, flash[:notice]
  end
  
  test "timer validation and error handling" do
    user = users(:one)
    
    # Authenticate
    post session_url, params: { 
      email_address: user.email_address, 
      password: "password" 
    }
    follow_redirect!
    
    # Test validation errors
    assert_no_difference "Timer.count" do
      post timers_path, params: {
        timer: { task_name: "" }
      }
    end
    
    assert_response :unprocessable_entity
    assert_match /Task name can&#39;t be blank/, response.body
    
    # Test state transition errors
    timer = user.timers.create!(task_name: "Error test", status: "stopped")
    
    # Try to pause a stopped timer
    patch pause_timer_path(timer)
    assert_redirected_to timers_path
    follow_redirect!
    assert_match /Timer is not running/, flash[:alert]
    
    # Try to resume a stopped timer
    patch resume_timer_path(timer)
    assert_redirected_to timers_path
    follow_redirect!
    assert_match /Timer is not paused/, flash[:alert]
    
    # Try to stop a stopped timer
    patch stop_timer_path(timer)
    assert_redirected_to timers_path
    follow_redirect!
    assert_match /Timer is not active/, flash[:alert]
  end
  
  test "multiple timer management" do
    user = users(:one)
    
    # Authenticate
    post session_url, params: { 
      email_address: user.email_address, 
      password: "password" 
    }
    follow_redirect!
    
    # Create multiple timers
    timer1 = user.timers.create!(task_name: "Task 1", status: "stopped")
    timer2 = user.timers.create!(task_name: "Task 2", status: "stopped")
    timer3 = user.timers.create!(task_name: "Task 3", status: "stopped")
    
    # Start multiple timers
    patch start_timer_path(timer1)
    patch start_timer_path(timer2)
    
    timer1.reload
    timer2.reload
    timer3.reload
    
    assert_equal "running", timer1.status
    assert_equal "running", timer2.status
    assert_equal "stopped", timer3.status
    
    # Manage timers independently
    patch pause_timer_path(timer1)
    patch stop_timer_path(timer2)
    patch start_timer_path(timer3)
    
    timer1.reload
    timer2.reload
    timer3.reload
    
    assert_equal "paused", timer1.status
    assert_equal "stopped", timer2.status
    assert_equal "running", timer3.status
    
    # Verify they can be accessed on the timers page
    get timers_path
    assert_response :success
    assert_match "Task 1", response.body
    assert_match "Task 2", response.body
    assert_match "Task 3", response.body
  end
  
  test "navigation and dashboard integration" do
    user = users(:one)
    
    # Authenticate
    post session_url, params: { 
      email_address: user.email_address, 
      password: "password" 
    }
    follow_redirect!
    
    # Create some test data
    running_timer = user.timers.create!(
      task_name: "Running task",
      status: "running",
      start_time: 1.hour.ago
    )
    
    completed_timer = user.timers.create!(
      task_name: "Completed task",
      status: "stopped",
      duration: 3600,
      start_time: 2.hours.ago,
      end_time: 1.hour.ago
    )
    
    # Test dashboard
    get dashboard_path
    assert_response :success
    assert_select "a[href='#{new_timer_path}']"
    assert_select "a[href='#{timers_path}']"
    assert_select "a[href='#{analytics_path}']"
    
    # Test timers index
    get timers_path
    assert_response :success
    assert_match "Running task", response.body
    assert_match "Completed task", response.body
    assert_select "a[href='#{new_timer_path}']"
    
    # Test new timer page
    get new_timer_path
    assert_response :success
    assert_select "form[action='#{timers_path}']"
    assert_select "input[name='timer[task_name]']"
    assert_select "input[name='timer[tags]']"
    
    # Test analytics page
    get analytics_path
    assert_response :success
    # Should have some basic analytics content
    assert_match "Analytics", response.body
  end

  private

  def travel(duration, &block)
    travel_to Time.current + duration, &block
  end
end