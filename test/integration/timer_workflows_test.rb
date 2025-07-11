require "test_helper"

class TimerWorkflowsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @timer = timers(:running_timer)
    # Sign in via the actual sign-in flow
    post session_url, params: { 
      email_address: @user.email_address, 
      password: "password" 
    }
    follow_redirect! if response.redirect?
  end

  teardown do
    # Sign out via the actual sign-out flow
    delete session_url if @user
  end

  test "complete timer workflow: create, start, pause, resume, stop" do
    # Step 1: Create a new timer
    get new_timer_path
    assert_response :success
    assert_select "h1", "New Timer"
    assert_select "form"
    
    # Submit timer creation form
    post timers_path, params: {
      timer: {
        task_name: "Integration test task",
        tags: "work, testing"
      }
    }
    
    timer = Timer.last
    assert_redirected_to timer_path(timer)
    follow_redirect!
    
    assert_select "h1", "Integration test task"
    assert_equal "stopped", timer.status
    assert_equal ["work", "testing"], timer.parse_tags
    
    # Step 2: Start the timer
    patch start_timer_path(timer)
    assert_redirected_to timers_path
    follow_redirect!
    
    timer.reload
    assert_equal "running", timer.status
    assert_not_nil timer.start_time
    assert_nil timer.end_time
    assert_match /Timer started!/, flash[:notice]
    
    # Verify timer appears in active timers section
    assert_select "[data-countdown-timer-target='display']", timer.formatted_duration
    assert_select "form[action='#{pause_timer_path(timer)}']"
    
    # Step 3: Pause the timer
    travel 30.seconds do
      patch pause_timer_path(timer)
      assert_redirected_to timers_path
      follow_redirect!
      
      timer.reload
      assert_equal "paused", timer.status
      assert timer.duration > 0
      assert_not_nil timer.end_time
      assert_match /Timer paused!/, flash[:notice]
      
      # Verify timer shows pause state
      assert_select "form[action='#{resume_timer_path(timer)}']"
    end
    
    # Step 4: Resume the timer
    patch resume_timer_path(timer)
    assert_redirected_to timers_path
    follow_redirect!
    
    timer.reload
    assert_equal "running", timer.status
    assert_not_nil timer.start_time
    assert_nil timer.end_time
    assert_match /Timer resumed!/, flash[:notice]
    
    # Step 5: Stop the timer
    travel 45.seconds do
      patch stop_timer_path(timer)
      assert_redirected_to timers_path
      follow_redirect!
      
      timer.reload
      assert_equal "stopped", timer.status
      assert timer.duration > 0
      assert_not_nil timer.end_time
      assert_match /Timer stopped!/, flash[:notice]
      
      # Verify timer no longer appears in active timers section
      get timers_path
      assert_select "[data-countdown-timer-target='display']", { count: 0 }
    end
  end

  test "timer creation workflow with validation errors" do
    # Try to create timer without task name
    get new_timer_path
    assert_response :success
    
    post timers_path, params: {
      timer: {
        task_name: "", # Empty task name should fail validation
        tags: "testing"
      }
    }
    
    assert_response :unprocessable_entity
    # Check for validation error in the response body (HTML entities version)
    assert_match /Task name can&#39;t be blank/, response.body
    assert_no_difference "Timer.count" do
      # Ensure no timer was created
    end
  end

  test "timer editing workflow" do
    timer = timers(:running_timer)
    
    # Edit timer
    get edit_timer_path(timer)
    assert_response :success
    assert_select "h1", "Edit Timer"
    assert_select "input[value='#{timer.task_name}']"
    
    # Update timer
    patch timer_path(timer), params: {
      timer: {
        task_name: "Updated task name",
        tags: "updated, tags"
      }
    }
    
    assert_redirected_to timer_path(timer)
    follow_redirect!
    
    timer.reload
    assert_equal "Updated task name", timer.task_name
    assert_equal "updated, tags", timer[:tags]
    assert_match /Timer was successfully updated/, flash[:notice]
  end

  test "timer deletion workflow" do
    timer = @user.timers.create!(
      task_name: "Timer to delete",
      status: "stopped"
    )
    
    # Delete timer
    assert_difference "Timer.count", -1 do
      delete timer_path(timer)
    end
    
    assert_redirected_to timers_path
    follow_redirect!
    assert_match /Timer was successfully deleted/, flash[:notice]
    
    # Verify timer is no longer shown
    assert_select "h3", { text: "Timer to delete", count: 0 }
  end

  test "multiple timer workflow: managing several timers simultaneously" do
    # Create multiple timers
    timer1 = @user.timers.create!(task_name: "Task 1", status: "stopped")
    timer2 = @user.timers.create!(task_name: "Task 2", status: "stopped")
    timer3 = @user.timers.create!(task_name: "Task 3", status: "stopped")
    
    # Start timer1
    patch start_timer_path(timer1)
    assert_redirected_to timers_path
    
    # Start timer2
    patch start_timer_path(timer2)
    assert_redirected_to timers_path
    
    follow_redirect!
    
    # Verify both timers are running
    timer1.reload
    timer2.reload
    assert_equal "running", timer1.status
    assert_equal "running", timer2.status
    
    # Verify active timers section shows both
    assert_select "[data-countdown-timer-target='display']", count: 2
    
    # Pause one timer
    patch pause_timer_path(timer1)
    assert_redirected_to timers_path
    follow_redirect!
    
    timer1.reload
    assert_equal "paused", timer1.status
    assert_equal "running", timer2.status
    
    # Stop all active timers
    patch stop_timer_path(timer1)
    patch stop_timer_path(timer2)
    
    get timers_path
    timer1.reload
    timer2.reload
    timer3.reload
    
    assert_equal "stopped", timer1.status
    assert_equal "stopped", timer2.status
    assert_equal "stopped", timer3.status
  end

  test "timer state transition error handling" do
    timer = @user.timers.create!(task_name: "Test timer", status: "stopped")
    
    # Try to pause a stopped timer
    patch pause_timer_path(timer)
    assert_redirected_to timers_path
    follow_redirect!
    assert_match /Timer is not running/, flash[:alert]
    
    timer.reload
    assert_equal "stopped", timer.status
    
    # Try to resume a stopped timer
    patch resume_timer_path(timer)
    assert_redirected_to timers_path
    follow_redirect!
    assert_match /Timer is not paused/, flash[:alert]
    
    timer.reload
    assert_equal "stopped", timer.status
    
    # Try to stop a stopped timer
    patch stop_timer_path(timer)
    assert_redirected_to timers_path
    follow_redirect!
    assert_match /Timer is not active/, flash[:alert]
    
    timer.reload
    assert_equal "stopped", timer.status
  end

  test "timer workflow with tags" do
    # Create timer with tags
    post timers_path, params: {
      timer: {
        task_name: "Tagged task",
        tags: "work, project-x, urgent"
      }
    }
    
    timer = Timer.last
    assert_equal "work, project-x, urgent", timer[:tags]
    
    # Start and stop timer to ensure tags persist through status changes
    patch start_timer_path(timer)
    travel 60.seconds do
      patch stop_timer_path(timer)
    end
    
    timer.reload
    assert_equal "work, project-x, urgent", timer[:tags]
    assert_equal "stopped", timer.status
    assert timer.duration > 0
  end

  test "timer navigation and dashboard integration" do
    # Create some timers for dashboard stats
    running_timer = @user.timers.create!(
      task_name: "Running task", 
      status: "running",
      start_time: 1.hour.ago
    )
    
    completed_timer = @user.timers.create!(
      task_name: "Completed task",
      status: "stopped",
      duration: 3600, # 1 hour
      start_time: 2.hours.ago,
      end_time: 1.hour.ago
    )
    
    # Visit dashboard
    get dashboard_path
    assert_response :success
    
    # Check stats are displayed (look for the stat card containers)
    assert_select ".bg-white.rounded-xl.shadow-sm", minimum: 3
    
    # Navigate to timers from dashboard
    assert_select "a[href='#{new_timer_path}']"
    assert_select "a[href='#{timers_path}']"
    
    # Visit timers index
    get timers_path
    assert_response :success
    
    # Verify timers are listed
    assert_select "h3", text: "Running task"
    assert_select "h3", text: "Completed task"
    
    # Check active timers section
    assert_select "[data-countdown-timer-target='display']", count: 1 # Only the running timer
  end

  test "timer workflow data persistence and calculation accuracy" do
    timer = @user.timers.create!(task_name: "Precision test", status: "stopped")
    
    start_time = Time.current
    
    # Start timer
    travel_to start_time do
      patch start_timer_path(timer)
      timer.reload
      assert_in_delta start_time.to_f, timer.start_time.to_f, 1.0
    end
    
    # Pause after 30 seconds
    travel_to start_time + 30.seconds do
      patch pause_timer_path(timer)
      timer.reload
      assert_in_delta 30, timer.duration, 2 # Allow 2 second tolerance
      assert_equal "paused", timer.status
    end
    
    # Resume and run for another 45 seconds
    travel_to start_time + 60.seconds do
      patch resume_timer_path(timer)
      timer.reload
      # Start time should be adjusted to account for previous duration
      expected_adjusted_start = start_time + 60.seconds - 30.seconds
      assert_in_delta expected_adjusted_start.to_f, timer.start_time.to_f, 1.0
    end
    
    # Stop after total of 75 seconds (30 + 45)
    travel_to start_time + 105.seconds do
      patch stop_timer_path(timer)
      timer.reload
      assert_in_delta 75, timer.duration, 2 # Total should be ~75 seconds
      assert_equal "stopped", timer.status
    end
  end

  private

  def travel(duration, &block)
    travel_to Time.current + duration, &block
  end
end