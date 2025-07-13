require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "user without account sees appropriate message" do
    visit root_path
    
    # Should redirect to login
    assert_current_path new_session_path
    
    # Check for the message about contacting administrator
    assert_text "Contact your administrator to create an account"
    assert_text "New to Todo Timers?"
  end

  test "user can sign in" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password123"
    )
    
    visit root_path
    
    fill_in "Email address", with: "test@example.com"
    fill_in "Password", with: "password123"
    
    click_button "Sign in"
    
    # Should be logged in
    assert_current_path root_path
    assert_text "test@example.com"
    assert_selector "h1", text: "Timers"
  end

  test "user can sign out" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password123"
    )
    
    # Sign in first
    visit new_session_path
    fill_in "Email address", with: "test@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign in"
    
    # Now sign out
    click_button "Sign Out"
    
    # Should be redirected to login
    assert_current_path new_session_path
    assert_text "Welcome back"
  end

  test "invalid login shows error" do
    visit new_session_path
    
    fill_in "Email address", with: "wrong@example.com"
    fill_in "Password", with: "wrongpassword"
    
    click_button "Sign in"
    
    assert_text "Try another email address or password"
    assert_current_path new_session_path
  end

  test "protected pages redirect to login" do
    # Try to access protected pages
    visit root_path
    assert_current_path new_session_path
    
    visit timers_path
    assert_current_path new_session_path
    
    visit analytics_path
    assert_current_path new_session_path
  end

  test "password reset flow" do
    user = User.create!(
      email_address: "reset@example.com",
      password: "oldpassword"
    )
    
    visit new_session_path
    click_link "Forgot password?"
    
    # Should be on password reset page
    assert_current_path new_password_path
    
    fill_in "Email address", with: "reset@example.com"
    click_button "Email reset instructions"
    
    # In a real app, we'd check email was sent
    # For now, just verify we're redirected back to login
    assert_current_path new_session_path
  end

  test "session persists across page loads" do
    user = User.create!(
      email_address: "persist@example.com",
      password: "password123"
    )
    
    # Sign in
    visit new_session_path
    fill_in "Email address", with: "persist@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign in"
    
    # Navigate around
    visit timers_path
    assert_text "persist@example.com"
    
    visit analytics_path
    assert_text "persist@example.com"
    
    # Still logged in
    visit root_path
    assert_text "persist@example.com"
  end

  test "mobile menu shows authentication state" do
    user = User.create!(
      email_address: "mobile@example.com",
      password: "password123"
    )
    
    # Make window mobile size
    page.driver.browser.manage.window.resize_to(375, 667)
    
    visit new_session_path
    fill_in "Email address", with: "mobile@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign in"
    
    # Open mobile menu
    find("button[aria-controls='mobile-menu']").click
    
    # Should see email and sign out in mobile menu
    within "#mobile-menu" do
      assert_text "mobile@example.com"
      assert_button "Sign Out"
    end
  end
end