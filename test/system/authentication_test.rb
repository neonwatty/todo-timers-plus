require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "user can sign up" do
    visit root_path
    
    # Should redirect to login
    assert_current_path new_session_path
    
    click_link "Sign up"
    
    fill_in "Email address", with: "newuser@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    
    click_button "Sign up"
    
    # Should be logged in and redirected to dashboard
    assert_current_path dashboard_path
    assert_text "Welcome to Todo Timers+"
    assert_text "newuser@example.com"
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
    assert_current_path dashboard_path
    assert_text "test@example.com"
    assert_selector "h1", text: "Dashboard"
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
    assert_text "Sign in to your account"
  end

  test "invalid login shows error" do
    visit new_session_path
    
    fill_in "Email address", with: "wrong@example.com"
    fill_in "Password", with: "wrongpassword"
    
    click_button "Sign in"
    
    assert_text "Invalid email or password"
    assert_current_path session_path
  end

  test "protected pages redirect to login" do
    # Try to access protected pages
    visit dashboard_path
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
    
    fill_in "Email address", with: "reset@example.com"
    click_button "Send password reset email"
    
    # In a real app, we'd check email was sent
    # For now, just verify the flash message
    assert_text "password reset"
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
    visit dashboard_path
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