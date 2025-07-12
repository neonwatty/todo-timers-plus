require "test_helper"

class TimerNotesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @timer = timers(:running_timer)
    sign_in_as @user
  end

  test "should create timer with notes" do
    assert_difference("Timer.count") do
      post timers_path, params: {
        timer: {
          task_name: "Timer with Notes",
          notes: "This is a test note for the timer."
        }
      }
    end

    timer = Timer.last
    assert_equal "This is a test note for the timer.", timer.notes
    assert_redirected_to timer_path(timer)
  end

  test "should update timer notes via form" do
    patch timer_path(@timer), params: {
      timer: {
        notes: "Updated notes content"
      }
    }

    @timer.reload
    assert_equal "Updated notes content", @timer.notes
    assert_redirected_to timer_path(@timer)
  end

  test "should update timer notes via AJAX" do
    patch timer_path(@timer), params: {
      timer: {
        notes: "AJAX updated notes"
      }
    }, as: :json

    assert_response :success
    @timer.reload
    assert_equal "AJAX updated notes", @timer.notes

    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal "AJAX updated notes", json_response["notes"]
  end

  test "should validate notes length" do
    long_notes = "a" * 2001  # Exceeds 2000 character limit

    patch timer_path(@timer), params: {
      timer: {
        notes: long_notes
      }
    }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
    assert_includes json_response["errors"].join, "too long"
  end

  test "should display notes on timer show page" do
    @timer.update!(notes: "Test notes for display")

    get timer_path(@timer)
    assert_response :success
    assert_select "p", text: "Test notes for display"
  end

  test "should display truncated notes in timer list" do
    @timer.update!(notes: "This is a long note that should be truncated when displayed in the timer list view")

    get timers_path
    assert_response :success
    assert_select "p", text: /Notes:.*This is a long note/
  end

  test "should display notes in timer card" do
    @timer.update!(notes: "Card notes test")

    get timers_path
    assert_response :success
    assert_select "p", text: "Card notes test"
  end

  test "should handle empty notes" do
    @timer.update!(notes: "")

    get timer_path(@timer)
    assert_response :success
    # Should show empty state
    assert_select "p", text: "No notes added yet. Click \"Add Notes\" to get started."
  end

  test "should preserve notes when updating other timer fields" do
    @timer.update!(notes: "Original notes")

    patch timer_path(@timer), params: {
      timer: {
        task_name: "Updated Task Name"
      }
    }

    @timer.reload
    assert_equal "Original notes", @timer.notes
    assert_equal "Updated Task Name", @timer.task_name
  end

  test "should validate notes in timer creation form" do
    post timers_path, params: {
      timer: {
        task_name: "Valid Timer",
        notes: "a" * 2001  # Too long
      }
    }

    assert_response :unprocessable_entity
    assert_select ".text-red-700", text: /too long/
  end

  test "should escape HTML in notes display" do
    html_notes = "<script>alert('xss')</script><b>Bold text</b>"
    @timer.update!(notes: html_notes)

    get timer_path(@timer)
    assert_response :success
    
    # Check that HTML is escaped in the notes display area specifically
    assert_select "p[data-notes-editor-target='notesDisplay']" do |elements|
      element_text = elements.first.content
      # Should contain escaped HTML, not execute it
      assert_includes element_text, "<script>alert('xss')</script>"
      assert_includes element_text, "<b>Bold text</b>"
    end
    
    # Make sure the raw HTML isn't in the response as executable code
    assert_not_includes response.body, "alert('xss')"
  end

  test "should handle AJAX error responses" do
    # Test with invalid data that will fail validation
    patch timer_path(@timer), params: {
      timer: {
        notes: "a" * 2001  # Too long
      }
    }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
    assert json_response["errors"].present?
  end

  test "should include notes in JSON response for API" do
    @timer.update!(notes: "API test notes")

    get timer_path(@timer, format: :json)
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal "API test notes", json_response["notes"]
  end

  test "should preserve line breaks in notes display" do
    multiline_notes = "Line 1\nLine 2\n\nLine 4"
    @timer.update!(notes: multiline_notes)

    get timer_path(@timer)
    assert_response :success
    
    # Check that the CSS class for preserving whitespace is present
    assert_select "p.whitespace-pre-wrap[data-notes-editor-target='notesDisplay']"
    
    # Check that the multiline content is stored correctly
    assert_select "p[data-notes-editor-target='notesDisplay']" do |elements|
      # The HTML parser may normalize whitespace, but the content should be there
      element_text = elements.first.content
      assert_includes element_text, "Line 1"
      assert_includes element_text, "Line 2" 
      assert_includes element_text, "Line 4"
    end
  end
end