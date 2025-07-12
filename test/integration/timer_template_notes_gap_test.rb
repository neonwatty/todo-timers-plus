require "test_helper"

class TimerTemplateNotesGapTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "timer templates should support notes (now implemented)" do
    # This test verifies that templates now support notes
    
    # Create a template with notes - should succeed
    template = @user.timer_templates.create!(
      name: "Template with Notes",
      task_name: "Test Task",
      notes: "Template notes that should be preserved"
    )
    
    assert template.persisted?
    assert_equal "Template notes that should be preserved", template.notes
  end

  test "creating timer from template preserves notes context" do
    # Now that templates support notes, they should be preserved
    
    template = @user.timer_templates.create!(
      name: "Test Template",
      task_name: "Task from template",
      timer_type: "stopwatch",
      notes: "Important context from template"
    )
    
    # Create timer from template
    post create_timer_timer_template_path(template)
    
    timer = Timer.last
    # Notes should now be preserved from template
    assert_equal "Important context from template", timer.notes
  end

  test "save as template preserves notes" do
    # When saving a timer with notes as template, 
    # the notes should now be preserved in the template
    
    post timers_path, params: {
      timer: {
        task_name: "Timer with Notes",
        notes: "Important context that should be preserved"
      },
      save_as_template: "1"
    }
    
    timer = Timer.last
    template = TimerTemplate.last
    
    # Timer has notes
    assert_equal "Important context that should be preserved", timer.notes
    
    # Template should now also have notes
    assert_equal "Important context that should be preserved", template.notes
  end
end