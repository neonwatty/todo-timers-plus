require "test_helper"

class TimersAjaxTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    post session_url, params: { 
      email_address: @user.email_address, 
      password: "password" 
    }
    
    @timer = @user.timers.create!(
      task_name: "AJAX Test Timer",
      timer_type: "countdown",
      target_duration: 600,
      remaining_duration: 600,
      status: "stopped"
    )
  end

  test "start timer via AJAX returns JSON" do
    patch start_timer_path(@timer), headers: { "Accept" => "application/json" }
    
    assert_response :success
    json = JSON.parse(response.body)
    
    assert_equal @timer.id, json["id"]
    assert_equal "running", json["status"]
    assert_not_nil json["start_time"]
    assert_equal "AJAX Test Timer", json["task_name"]
    assert_equal 600, json["target_duration"]
    assert json["is_countdown"]
  end

  test "pause timer via AJAX returns updated state" do
    @timer.start!
    
    travel 30.seconds do
      patch pause_timer_path(@timer), headers: { "Accept" => "application/json" }
      
      assert_response :success
      json = JSON.parse(response.body)
      
      assert_equal "paused", json["status"]
      assert_in_delta 570, json["remaining_duration"], 1 # 600 - 30
      assert_in_delta 5, json["progress_percentage"], 0.5
    end
  end

  test "resume timer via AJAX" do
    @timer.update!(status: "paused", remaining_duration: 400)
    
    patch resume_timer_path(@timer), headers: { "Accept" => "application/json" }
    
    assert_response :success
    json = JSON.parse(response.body)
    
    assert_equal "running", json["status"]
    assert_equal 400, json["remaining_duration"]
    assert_not_nil json["start_time"]
  end

  test "stop timer via AJAX" do
    @timer.start!
    
    travel 45.seconds do
      patch stop_timer_path(@timer), headers: { "Accept" => "application/json" }
      
      assert_response :success
      json = JSON.parse(response.body)
      
      assert_equal "stopped", json["status"]
      assert_not_nil json["end_time"]
      assert_in_delta 45, json["duration"], 1
    end
  end

  test "reset timer via AJAX" do
    @timer.update!(
      status: "paused",
      remaining_duration: 200,
      duration: 400
    )
    
    patch reset_timer_path(@timer), headers: { "Accept" => "application/json" }
    
    assert_response :success
    json = JSON.parse(response.body)
    
    assert_equal "stopped", json["status"]
    assert_equal 600, json["remaining_duration"]
    assert_equal 0, json["duration"]
    assert_nil json["start_time"]
    assert_nil json["end_time"]
  end

  test "AJAX requests with HTML format redirect" do
    # Verify HTML requests still redirect
    patch start_timer_path(@timer)
    assert_redirected_to timers_path
    
    patch pause_timer_path(@timer.reload)
    assert_redirected_to timers_path
  end

  test "handle expired timer via AJAX" do
    # Create an expired timer
    @timer.update!(
      status: "running",
      start_time: 2.minutes.ago,
      remaining_duration: 10
    )
    
    get timer_path(@timer), headers: { "Accept" => "application/json" }
    
    assert_response :success
    json = JSON.parse(response.body)
    
    assert json["is_expired"]
    assert_equal 0, json["remaining_time"]
    assert_equal 100, json["progress_percentage"]
  end

  test "concurrent AJAX requests maintain timer state" do
    # Start timer
    patch start_timer_path(@timer), headers: { "Accept" => "application/json" }
    
    # Simulate multiple rapid AJAX calls
    3.times do
      get timer_path(@timer), headers: { "Accept" => "application/json" }
      assert_response :success
    end
    
    # Timer should still be in consistent state
    @timer.reload
    assert_equal "running", @timer.status
  end
end