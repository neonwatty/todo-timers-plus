require "test_helper"

class TimersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @timer = timers(:running_timer)
    sign_in_as(@user)
  end

  test "should get index" do
    get timers_url
    assert_response :success
    assert_select "h2", "Your Timers"
  end

  test "should get new" do
    get new_timer_url
    assert_response :success
    assert_select "form"
  end

  test "should create timer" do
    assert_difference("Timer.count") do
      post timers_url, params: { 
        timer: { 
          task_name: "New Test Timer",
          tags: "test, development"
        } 
      }
    end

    assert_redirected_to timer_url(Timer.last)
    assert_equal "Timer was successfully created.", flash[:notice]
  end

  test "should not create timer with invalid params" do
    assert_no_difference("Timer.count") do
      post timers_url, params: { 
        timer: { 
          task_name: "",
          tags: "test"
        } 
      }
    end

    assert_response :unprocessable_entity
  end

  test "should show timer" do
    get timer_url(@timer)
    assert_response :success
    assert_select "h1", @timer.task_name
  end

  test "should get edit" do
    get edit_timer_url(@timer)
    assert_response :success
    assert_select "form"
  end

  test "should update timer" do
    patch timer_url(@timer), params: { 
      timer: { 
        task_name: "Updated Timer Name" 
      } 
    }
    assert_redirected_to timer_url(@timer)
    @timer.reload
    assert_equal "Updated Timer Name", @timer.task_name
    assert_equal "Timer was successfully updated.", flash[:notice]
  end

  test "should not update timer with invalid params" do
    patch timer_url(@timer), params: { 
      timer: { 
        task_name: "" 
      } 
    }
    assert_response :unprocessable_entity
  end

  test "should destroy timer" do
    assert_difference("Timer.count", -1) do
      delete timer_url(@timer)
    end

    assert_redirected_to timers_url
    assert_equal "Timer was successfully destroyed.", flash[:notice]
  end

  test "should start timer" do
    timer = @user.timers.create!(task_name: "Test Timer", status: "pending")
    
    patch start_timer_url(timer)
    assert_redirected_to timer_url(timer)
    
    timer.reload
    assert_equal "running", timer.status
    assert_not_nil timer.start_time
  end

  test "should pause timer" do
    patch pause_timer_url(@timer)
    assert_redirected_to timer_url(@timer)
    
    @timer.reload
    assert_equal "paused", @timer.status
  end

  test "should resume timer" do
    timer = timers(:paused_timer)
    
    patch resume_timer_url(timer)
    assert_redirected_to timer_url(timer)
    
    timer.reload
    assert_equal "running", timer.status
  end

  test "should stop timer" do
    patch stop_timer_url(@timer)
    assert_redirected_to timer_url(@timer)
    
    @timer.reload
    assert_equal "stopped", @timer.status
    assert_not_nil @timer.end_time
  end

  test "should not access other user's timer" do
    other_user = users(:two)
    other_timer = timers(:stopped_timer) # belongs to user two
    
    get timer_url(other_timer)
    assert_response :not_found
  end

  test "should require authentication" do
    sign_out
    
    get timers_url
    assert_redirected_to new_session_url
  end

end