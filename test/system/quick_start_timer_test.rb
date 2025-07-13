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
  
  test "quick starting countdown timer with preset" do
    user = User.create!(
      email_address: "countdown@example.com", 
      password: "password123"
    )
    
    # Sign in
    visit new_session_path
    fill_in "Email address", with: "countdown@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign in"
    
    # Fill task name
    fill_in "What are you working on?", with: "Pomodoro session"
    
    # Select countdown and click 25 min preset
    choose "Countdown Timer"
    click_button "25 min"
    
    # Verify timer was created correctly
    assert_text "Timer started! 🚀"
    
    timer = user.timers.last
    assert_equal "Pomodoro session", timer.task_name
    assert_equal "countdown", timer.timer_type
    assert_equal 1500, timer.target_duration
    assert_equal "running", timer.status
  end
  
  test "quick starting countdown with custom duration" do
    user = User.create!(
      email_address: "custom@example.com",
      password: "password123"
    )
    
    # Sign in
    visit new_session_path
    fill_in "Email address", with: "custom@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign in"
    
    # Fill out form
    fill_in "What are you working on?", with: "Custom timer"
    choose "Countdown Timer"
    fill_in "Custom", with: "45"
    
    # Click the custom start button
    within ".flex.items-center.gap-2" do
      click_button "Start"
    end
    
    # Verify timer was created
    assert_text "Timer started! 🚀"
    
    timer = user.timers.last
    assert_equal "Custom timer", timer.task_name
    assert_equal "countdown", timer.timer_type
    assert_equal 2700, timer.target_duration # 45 minutes
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
    click_button "Advanced Options"
    
    # Should see advanced fields
    assert_text "Tags"
    assert_text "Notes"
    
    # Fill out form
    fill_in "What are you working on?", with: "Tagged task"
    fill_in "Tags", with: "work, focus"
    fill_in "Notes", with: "Remember to take breaks"
    
    click_button "Start Stopwatch"
    
    # Verify timer was created correctly
    assert_text "Timer started! 🚀"
    
    timer = user.timers.last
    assert_equal "Tagged task", timer.task_name
    assert_equal "stopwatch", timer.timer_type
    assert_equal "work, focus", timer[:tags]
    assert_equal "Remember to take breaks", timer.notes
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