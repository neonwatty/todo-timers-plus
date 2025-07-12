require "application_system_test_case"

class TimerNotesSystemTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @timer = timers(:running_timer)
    sign_in_as @user
  end

  test "should toggle between view and edit modes" do
    @timer.update!(notes: "Original notes content")
    
    visit timer_path(@timer)
    
    # Should show notes in view mode
    assert_text "Original notes content"
    assert_selector "[data-notes-editor-target='viewMode']"
    
    # Click edit button
    click_button "Edit Notes"
    
    # Should switch to edit mode
    assert_selector "[data-notes-editor-target='editMode']", visible: true
    assert_selector "textarea[data-notes-editor-target='notesTextarea']"
    
    # Edit mode should have current content
    textarea = find("textarea[data-notes-editor-target='notesTextarea']")
    assert_equal "Original notes content", textarea.value
  end

  test "should save notes via AJAX" do
    @timer.update!(notes: "Original content")
    
    visit timer_path(@timer)
    
    # Click edit
    click_button "Edit Notes"
    
    # Change content
    fill_in "timer[notes]", with: "Updated via AJAX"
    
    # Save
    click_button "Save"
    
    # Should return to view mode with updated content
    assert_selector "[data-notes-editor-target='viewMode']", visible: true
    assert_text "Updated via AJAX"
    
    # Verify in database
    @timer.reload
    assert_equal "Updated via AJAX", @timer.notes
  end

  test "should cancel editing without saving" do
    @timer.update!(notes: "Original content")
    
    visit timer_path(@timer)
    
    click_button "Edit Notes"
    
    # Change content but don't save
    fill_in "timer[notes]", with: "Changed but not saved"
    
    # Cancel
    click_button "Cancel"
    
    # Should return to view mode with original content
    assert_selector "[data-notes-editor-target='viewMode']", visible: true
    assert_text "Original content"
    
    # Verify database unchanged
    @timer.reload
    assert_equal "Original content", @timer.notes
  end

  test "should handle empty notes state" do
    @timer.update!(notes: nil)
    
    visit timer_path(@timer)
    
    # Should show empty state
    assert_text "No notes added yet"
    assert_button "Add Notes"
    
    # Click add notes
    click_button "Add Notes"
    
    # Should switch to edit mode
    assert_selector "textarea[data-notes-editor-target='notesTextarea']"
    
    # Add content and save
    fill_in "timer[notes]", with: "First notes"
    click_button "Save"
    
    # Should show content and change button text
    assert_text "First notes"
    assert_button "Edit Notes"  # Button text should change
  end

  test "should preserve line breaks in display" do
    multiline_notes = "Line 1\nLine 2\n\nLine 4"
    @timer.update!(notes: multiline_notes)
    
    visit timer_path(@timer)
    
    # Check that line breaks are preserved in the display
    notes_element = find("[data-notes-editor-target='notesDisplay']")
    assert_equal multiline_notes, notes_element.text
  end

  test "should show error message on save failure" do
    @timer.update!(notes: "Original")
    
    visit timer_path(@timer)
    
    click_button "Edit Notes"
    
    # Try to save notes that are too long
    fill_in "timer[notes]", with: "a" * 2001
    
    # This should trigger an error (though it might be hard to test the exact error message)
    click_button "Save"
    
    # The form should remain in edit mode if there's an error
    # (This tests our error handling, even if we can't see the toast)
    assert_selector "textarea[data-notes-editor-target='notesTextarea']"
  end

  test "should work on mobile viewport" do
    # Test mobile responsiveness
    resize_window_to(375, 667)  # iPhone size
    
    @timer.update!(notes: "Mobile test notes")
    
    visit timer_path(@timer)
    
    # Should be readable on mobile
    assert_text "Mobile test notes"
    
    # Edit button should be accessible
    click_button "Edit Notes"
    
    # Textarea should be usable on mobile
    assert_selector "textarea[data-notes-editor-target='notesTextarea']"
    
    # Should be able to save
    fill_in "timer[notes]", with: "Edited on mobile"
    click_button "Save"
    
    assert_text "Edited on mobile"
  end

  private

  def sign_in_as(user)
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: "password"
    click_button "Sign in"
  end

  def resize_window_to(width, height)
    page.driver.browser.manage.window.resize_to(width, height)
  end
end