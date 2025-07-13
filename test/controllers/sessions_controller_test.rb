require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should get new" do
    get new_session_url
    assert_response :success
    assert_select "form"
    assert_select "h2", "Welcome back"
  end

  test "should create session with valid credentials" do
    post session_url, params: { 
      email_address: @user.email_address, 
      password: "password" 
    }
    
    assert_redirected_to root_url
    assert_not_nil cookies[:session_id]
  end

  test "should not create session with invalid email" do
    post session_url, params: { 
      email_address: "invalid@example.com", 
      password: "password" 
    }
    
    assert_redirected_to new_session_path
    assert_equal "Try another email address or password.", flash[:alert]
  end

  test "should not create session with invalid password" do
    post session_url, params: { 
      email_address: @user.email_address, 
      password: "wrongpassword" 
    }
    
    assert_redirected_to new_session_path
    assert_equal "Try another email address or password.", flash[:alert]
  end

  test "should destroy session" do
    # Sign in first
    post session_url, params: { 
      email_address: @user.email_address, 
      password: "password" 
    }
    assert_not_nil cookies[:session_id]
    
    # Then sign out
    delete session_url
    assert_redirected_to new_session_url
    assert cookies[:session_id].blank?
  end

  test "should handle access to login page when already signed in" do
    # Sign in first
    post session_url, params: { 
      email_address: @user.email_address, 
      password: "password" 
    }
    
    # The controller doesn't implement redirect logic for already signed in users
    get new_session_url
    assert_response :success
  end
end