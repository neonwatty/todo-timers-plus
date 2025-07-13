require "test_helper"

class TimerWorkflowsSimplifiedTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
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

  test "create and manage a timer complete workflow" do
    # Step 1: Create a new timer
    assert_difference "Timer.count", 1 do
      post timers_path, params: {
        timer: {
          task_name: "Integration test task",
          tags: "work, testing"
        }
      }
    end
    
    timer = Timer.last
    assert_redirected_to timer_path(timer)
    assert_equal "stopped", timer.status
    assert_equal "work, testing", timer[:tags]
    assert_equal @user.id, timer.user_id
    
    # Step 2: Start the timer
    patch start_timer_path(timer)
    assert_redirected_to timers_path
    
    timer.reload
    assert_equal "running", timer.status
    assert_not_nil timer.start_time
    assert_nil timer.end_time
    
    # Step 3: Pause the timer after some time
    travel 30.seconds do
      patch pause_timer_path(timer)
      assert_redirected_to timers_path
      
      timer.reload
      assert_equal "paused", timer.status
      assert timer.duration > 0
      assert_nil timer.end_time  # end_time is only set when stopped
    end
    
    # Step 4: Resume the timer
    patch resume_timer_path(timer)
    assert_redirected_to timers_path
    
    timer.reload
    assert_equal "running", timer.status
    assert_not_nil timer.start_time
    assert_nil timer.end_time
    
    # Step 5: Stop the timer
    travel 60.seconds do
      patch stop_timer_path(timer)
      assert_redirected_to timers_path
      
      timer.reload
      assert_equal "stopped", timer.status
      assert timer.duration > 0
      assert_not_nil timer.end_time
    end
  end

  test "timer state transition validations" do
    timer = @user.timers.create!(task_name: "Test timer", status: "stopped")
    
    # Try to pause a stopped timer - should redirect with alert
    patch pause_timer_path(timer)
    assert_redirected_to timers_path
    follow_redirect!
    assert_match /Timer is not running/, flash[:alert]
    
    # Try to resume a stopped timer - should redirect with alert
    patch resume_timer_path(timer)
    assert_redirected_to timers_path
    follow_redirect!
    assert_match /Timer is not paused/, flash[:alert]
    
    # Try to stop a stopped timer - should redirect with alert
    patch stop_timer_path(timer)
    assert_redirected_to timers_path
    follow_redirect!
    assert_match /Timer is not active/, flash[:alert]
  end

  test "timer CRUD operations" do
    # Create timer
    assert_difference "Timer.count", 1 do
      post timers_path, params: {
        timer: {
          task_name: "CRUD test timer",
          tags: "testing, crud"
        }
      }
    end
    
    timer = Timer.last
    
    # Read/Show timer
    get timer_path(timer)
    assert_response :success
    assert_match timer.task_name, response.body
    
    # Update timer
    patch timer_path(timer), params: {
      timer: {
        task_name: "Updated CRUD test timer",
        tags: "updated, testing"
      }
    }
    
    assert_redirected_to timer_path(timer)
    timer.reload
    assert_equal "Updated CRUD test timer", timer.task_name
    assert_equal "updated, testing", timer[:tags]
    
    # Delete timer
    assert_difference "Timer.count", -1 do
      delete timer_path(timer)
    end
    
    assert_redirected_to timers_path
  end

  test "multiple active timers workflow" do
    # Create and start multiple timers
    timer1 = @user.timers.create!(task_name: "Task 1", status: "stopped")
    timer2 = @user.timers.create!(task_name: "Task 2", status: "stopped")
    
    # Start both timers
    patch start_timer_path(timer1)
    patch start_timer_path(timer2)
    
    # Verify both are running
    timer1.reload
    timer2.reload
    assert_equal "running", timer1.status
    assert_equal "running", timer2.status
    
    # Pause one, stop the other
    patch pause_timer_path(timer1)
    patch stop_timer_path(timer2)
    
    timer1.reload
    timer2.reload
    assert_equal "paused", timer1.status
    assert_equal "stopped", timer2.status
  end

  test "timer duration calculations" do
    timer = @user.timers.create!(task_name: "Duration test", status: "stopped")
    
    start_time = Time.current
    
    # Start timer
    travel_to start_time do
      patch start_timer_path(timer)
      timer.reload
    end
    
    # Pause after 30 seconds
    travel_to start_time + 30.seconds do
      patch pause_timer_path(timer)
      timer.reload
      assert_in_delta 30, timer.duration, 2
    end
    
    # Resume and run for 45 more seconds, then stop
    travel_to start_time + 60.seconds do
      patch resume_timer_path(timer)
    end
    
    travel_to start_time + 105.seconds do
      patch stop_timer_path(timer)
      timer.reload
      # Total should be approximately 75 seconds (30 + 45)
      assert_in_delta 75, timer.duration, 5
    end
  end

  test "navigation between timer pages" do
    timer = @user.timers.create!(task_name: "Navigation test", status: "stopped")
    
    # Test navigation from home (timers page)
    get root_path
    assert_response :success
    assert_select "a[href='#{new_timer_path}']"
    
    # Test navigation to timer form
    get new_timer_path
    assert_response :success
    assert_select "form[action='#{timers_path}']"
    
    # Test navigation to timers index
    get timers_path
    assert_response :success
    assert_select "a[href='#{new_timer_path}']"
    
    # Test navigation to individual timer
    get timer_path(timer)
    assert_response :success
    assert_match timer.task_name, response.body
    
    # Test navigation to edit form
    get edit_timer_path(timer)
    assert_response :success
    assert_select "form[action='#{timer_path(timer)}'][method='post']"
  end

  private

  def travel(duration, &block)
    travel_to Time.current + duration, &block
  end
end