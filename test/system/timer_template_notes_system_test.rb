require "application_system_test_case"

class TimerTemplateNotesSystemTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in_as @user
    
    # Create a template with notes for testing
    @template_with_notes = @user.timer_templates.create!(
      name: "Focus Template",
      task_name: "Deep Focus Session",
      timer_type: "countdown",
      target_duration: 1500, # 25 minutes
      tags: "focus, work, pomodoro",
      notes: "Turn off notifications, use noise-canceling headphones, and set phone to silent."
    )
    
    @template_without_notes = @user.timer_templates.create!(
      name: "Simple Template",
      task_name: "Simple Task",
      timer_type: "stopwatch"
    )
  end

  test "template selection populates notes in timer form" do
    visit new_timer_path
    
    # Open template section
    click_button "Use Template"
    
    # Select template with notes
    within "#template-section" do
      click_button @template_with_notes.name
    end
    
    # Verify notes field is populated
    notes_field = find("#timer_notes")
    assert_equal @template_with_notes.notes, notes_field.value
    
    # Verify other fields are also populated
    assert_equal @template_with_notes.task_name, find("#timer_task_name").value
    assert_equal @template_with_notes.tags, find("#timer_tags").value
    
    # Verify countdown radio is selected
    assert find("#timer_timer_type_countdown").checked?
  end

  test "template without notes leaves notes field empty" do
    visit new_timer_path
    
    # Open template section and select template without notes
    click_button "Use Template"
    
    within "#template-section" do
      click_button @template_without_notes.name
    end
    
    # Verify notes field remains empty
    notes_field = find("#timer_notes")
    assert_equal "", notes_field.value
  end

  test "creating timer from template form includes notes" do
    visit new_timer_path
    
    # Select template with notes
    click_button "Use Template"
    within "#template-section" do
      click_button @template_with_notes.name
    end
    
    # Submit the form
    click_button "Create Timer"
    
    # Verify timer was created with notes
    timer = Timer.last
    assert_equal @template_with_notes.notes, timer.notes
    assert_equal @template_with_notes.task_name, timer.task_name
    
    # Verify we're redirected to timers page
    assert_current_path timers_path
  end

  test "template notes display in template card" do
    visit timer_templates_path
    
    # Find the template card
    within "[data-turbo-frame=\"timer_template_#{@template_with_notes.id}\"]" do
      # Check that notes are displayed (truncated)
      assert_text "Turn off notifications"
      
      # Verify the notes section exists
      assert_selector "p", text: /Turn off notifications/
    end
  end

  test "template notes display on template show page" do
    visit timer_template_path(@template_with_notes)
    
    # Verify notes section is present
    assert_text "Notes"
    assert_text @template_with_notes.notes
    
    # Verify whitespace preservation class is present
    assert_selector "p.whitespace-pre-wrap", text: @template_with_notes.notes
  end

  test "creating template with notes through form" do
    visit new_timer_template_path
    
    fill_in "Name", with: "New Template with Notes"
    fill_in "Default Task Name", with: "New Task"
    fill_in "Tags", with: "test, system"
    fill_in "Notes", with: "System test notes for template creation"
    
    click_button "Create Template"
    
    # Verify template was created
    template = TimerTemplate.last
    assert_equal "System test notes for template creation", template.notes
    
    # Verify we're on the template show page
    assert_current_path timer_template_path(template)
    assert_text "System test notes for template creation"
  end

  test "editing template notes through form" do
    visit edit_timer_template_path(@template_with_notes)
    
    # Update notes
    fill_in "Notes", with: "Updated system test notes"
    click_button "Update Template"
    
    # Verify notes were updated
    @template_with_notes.reload
    assert_equal "Updated system test notes", @template_with_notes.notes
    
    # Verify we're redirected to show page with updated notes
    assert_current_path timer_template_path(@template_with_notes)
    assert_text "Updated system test notes"
  end

  test "direct template usage preserves notes" do
    visit timer_template_path(@template_with_notes)
    
    # Use the "Use Template" button (direct action)
    click_button "Use Template"
    
    # Verify timer was created with notes
    timer = Timer.last
    assert_equal @template_with_notes.notes, timer.notes
    assert_equal @template_with_notes.task_name, timer.task_name
    
    # Verify we're redirected to timers page
    assert_current_path timers_path
  end

  test "template success message appears when applied" do
    visit new_timer_path
    
    # Select template
    click_button "Use Template"
    within "#template-section" do
      click_button @template_with_notes.name
    end
    
    # Verify success message appears
    assert_text "Template \"#{@template_with_notes.name}\" applied!"
    
    # Message should disappear after a few seconds (we won't wait for this in test)
    # but we can verify the message element exists
    assert_selector ".fixed.top-4.right-4", text: /Template.*applied!/
  end

  test "clear template button resets notes field" do
    visit new_timer_path
    
    # Select template with notes
    click_button "Use Template"
    within "#template-section" do
      click_button @template_with_notes.name
    end
    
    # Verify notes are populated
    assert_equal @template_with_notes.notes, find("#timer_notes").value
    
    # Clear the template
    click_button "Clear Form"
    
    # Verify notes field is cleared
    assert_equal "", find("#timer_notes").value
  end

  test "save timer as template preserves notes" do
    visit new_timer_path
    
    fill_in "Task Name", with: "Timer with Notes"
    fill_in "Notes", with: "Notes to be preserved in template"
    check "Save this configuration as a template"
    
    click_button "Create Timer"
    
    # Verify template was created with notes
    template = TimerTemplate.last
    assert_equal "Notes to be preserved in template", template.notes
    assert_equal "Timer with Notes", template.name
  end

  test "multiline notes display properly" do
    multiline_notes = "Step 1: Prepare workspace\nStep 2: Set timer\n\nStep 3: Begin focus session"
    @template_with_notes.update!(notes: multiline_notes)
    
    visit timer_template_path(@template_with_notes)
    
    # Verify multiline notes are displayed with proper CSS class
    assert_selector "p.whitespace-pre-wrap", text: multiline_notes
    assert_text "Step 1: Prepare workspace"
    assert_text "Step 3: Begin focus session"
  end

  test "long notes are truncated in template cards" do
    long_notes = "This is a very long note that should be truncated in the template card view " * 10
    @template_with_notes.update!(notes: long_notes)
    
    visit timer_templates_path
    
    within "[data-turbo-frame=\"timer_template_#{@template_with_notes.id}\"]" do
      # Should show truncated version
      assert_text "This is a very long note"
      # Should not show the full text
      assert_no_text long_notes
    end
  end

  private

  def sign_in_as(user)
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: "password"
    click_button "Sign in"
  end
end