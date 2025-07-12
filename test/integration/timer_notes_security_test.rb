require "test_helper"

class TimerNotesSecurityTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two) 
    @timer = timers(:running_timer) # belongs to @user
    @other_timer = timers(:stopped_timer) # belongs to @other_user
    sign_in_as @user
  end

  test "should prevent unauthorized notes access" do
    # Try to view other user's timer notes
    get timer_path(@other_timer)
    assert_response :not_found
  end

  test "should prevent unauthorized notes modification via form" do
    # Try to update other user's timer notes via form
    patch timer_path(@other_timer), params: {
      timer: { notes: "Hacked notes!" }
    }
    assert_response :not_found
    
    # Verify notes weren't changed
    @other_timer.reload
    assert_not_equal "Hacked notes!", @other_timer.notes
  end

  test "should prevent unauthorized notes modification via AJAX" do
    # Try to update other user's timer notes via AJAX
    patch timer_path(@other_timer), params: {
      timer: { notes: "AJAX hacked notes!" }
    }, as: :json
    
    assert_response :not_found
    
    # Verify notes weren't changed
    @other_timer.reload
    assert_not_equal "AJAX hacked notes!", @other_timer.notes
  end

  test "should require CSRF token for notes updates" do
    # This tests that CSRF protection is working
    # Remove CSRF token and try to update
    ActionController::Base.allow_forgery_protection = true
    
    begin
      # Try updating without CSRF token
      patch timer_path(@timer), params: {
        timer: { notes: "No CSRF token" }
      }, headers: {
        "X-CSRF-Token" => "invalid-token"
      }
      
      # Should either fail or redirect (depending on Rails config)
      assert_not_equal 200, response.status
    ensure
      ActionController::Base.allow_forgery_protection = false
    end
  end

  test "should handle SQL injection attempts in notes" do
    malicious_notes = "'; DROP TABLE timers; --"
    
    patch timer_path(@timer), params: {
      timer: { notes: malicious_notes }
    }
    
    @timer.reload
    # Notes should be stored as-is (escaped), not executed
    assert_equal malicious_notes, @timer.notes
    
    # Verify table still exists
    assert Timer.table_exists?
    assert Timer.count > 0
  end

  test "should handle various XSS vectors in notes" do
    xss_vectors = [
      "<img src=x onerror=alert('xss')>",
      "javascript:alert('xss')",
      "<svg onload=alert('xss')>",
      "&#60;script&#62;alert('xss')&#60;/script&#62;",
      "<iframe src='javascript:alert(\"xss\")'></iframe>"
    ]
    
    xss_vectors.each do |vector|
      @timer.update!(notes: vector)
      
      get timer_path(@timer)
      assert_response :success
      
      # Should not contain executable JavaScript
      assert_not_includes response.body, "alert('xss')"
      assert_not_includes response.body, "alert(\"xss\")"
      
      # Content should be escaped
      assert_includes response.body, "&lt;" if vector.include?("<")
    end
  end

  test "should handle authentication bypass attempts" do
    sign_out
    
    # Try to access timer when not logged in
    get timer_path(@timer)
    assert_redirected_to new_session_path
    
    # Try to update notes when not logged in
    patch timer_path(@timer), params: {
      timer: { notes: "Anonymous update" }
    }
    assert_redirected_to new_session_path
    
    # Verify notes weren't changed
    @timer.reload
    assert_not_equal "Anonymous update", @timer.notes
  end

  private

  def sign_out
    delete session_path
  end
end