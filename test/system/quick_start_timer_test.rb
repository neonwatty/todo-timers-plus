require "application_system_test_case"

class QuickStartTimerTest < ApplicationSystemTestCase
  test "quick starting a timer from the home page" do
    user = User.create!(
      email_address: "quick@example.com",
      password: "password123"
    )
    
    # Sign in
    visit new_session_path
    fill_in "Email address", with: "quick@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign in"
    
    # Should see quick start form
    assert_current_path root_path
    assert_text "Quick Start Timer"
    assert_text "Start timing in seconds!"
    
    # Quick start a timer
    fill_in "What are you working on?", with: "Writing unit tests"
    click_button "Start Timer"
    
    # Should see timer started
    assert_text "Timer started! 🚀"
    assert_text "Writing unit tests"
    assert_text "Running"
    
    # Timer should appear in active timers
    within "#active_timers_grid" do
      assert_text "Writing unit tests"
      assert_selector "[data-countdown-timer-status-value='running']"
    end
    
    # Timer should also appear in all timers list
    within "#all_timers_list" do
      assert_text "Writing unit tests"
    end
  end
  
  test "quick starting with advanced options" do
    user = User.create!(
      email_address: "advanced@example.com", 
      password: "password123"
    )
    
    # Sign in
    visit new_session_path
    fill_in "Email address", with: "advanced@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign in"
    
    # Open advanced options
    find("button[title='More options']").click
    
    # Should see advanced fields
    assert_text "Timer Type"
    assert_text "Tags"
    
    # Select countdown timer
    choose "Countdown"
    assert_selector "label", text: "Duration (minutes)"
    
    # Fill out form
    fill_in "What are you working on?", with: "Pomodoro session"
    fill_in "Duration (minutes)", with: "25"
    fill_in "Tags", with: "work, focus"
    
    click_button "Start Timer"
    
    # Verify timer was created correctly
    assert_text "Timer started! 🚀"
    
    timer = user.timers.last
    assert_equal "Pomodoro session", timer.task_name
    assert_equal "countdown", timer.timer_type
    assert_equal 1500, timer.target_duration
    assert_equal "work, focus", timer[:tags]
  end
  
  test "selecting recent tasks" do
    user = User.create!(
      email_address: "recent@example.com",
      password: "password123"
    )
    
    # Create some existing timers
    user.timers.create!(task_name: "Email review", status: "stopped")
    user.timers.create!(task_name: "Team meeting", status: "stopped")
    
    # Sign in
    visit new_session_path
    fill_in "Email address", with: "recent@example.com"
    fill_in "Password", with: "password123" 
    click_button "Sign in"
    
    # Should see recent tasks
    assert_text "Recent tasks:"
    assert_button "Email review"
    assert_button "Team meeting"
    
    # Click a recent task
    click_button "Email review"
    
    # Should populate the input
    assert_field "What are you working on?", with: "Email review"
    
    # Start the timer
    click_button "Start Timer"
    
    assert_text "Timer started! 🚀"
    assert_text "Email review"
  end
end