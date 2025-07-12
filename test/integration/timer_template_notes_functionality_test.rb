require "test_helper"

class TimerTemplateNotesFunctionalityTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "should create timer template with notes" do
    assert_difference('TimerTemplate.count') do
      post timer_templates_path, params: {
        timer_template: {
          name: "Template with Notes",
          task_name: "Focus Session",
          timer_type: "countdown",
          duration_hours: "0",
          duration_minutes: "25",
          duration_seconds: "0",
          tags: "focus, work",
          notes: "Use this template for deep focus sessions. Turn off notifications."
        }
      }
    end

    template = TimerTemplate.last
    assert_equal "Use this template for deep focus sessions. Turn off notifications.", template.notes
    assert_redirected_to timer_template_path(template)
  end

  test "should update timer template notes" do
    template = @user.timer_templates.create!(
      name: "Original Template",
      task_name: "Original Task",
      notes: "Original notes"
    )

    patch timer_template_path(template), params: {
      timer_template: {
        notes: "Updated notes with new instructions"
      }
    }

    template.reload
    assert_equal "Updated notes with new instructions", template.notes
    assert_redirected_to timer_template_path(template)
  end

  test "should validate notes length in template" do
    post timer_templates_path, params: {
      timer_template: {
        name: "Valid Template",
        task_name: "Valid Task",
        notes: "a" * 2001  # Too long
      }
    }

    assert_response :unprocessable_entity
    assert_select ".text-red-700", text: /too long/
  end

  test "should display notes on template show page" do
    template = @user.timer_templates.create!(
      name: "Template with Notes",
      task_name: "Test Task",
      notes: "These are important template notes"
    )

    get timer_template_path(template)
    assert_response :success
    assert_select "p", text: "These are important template notes"
  end

  test "should display notes in template card" do
    template = @user.timer_templates.create!(
      name: "Card Template",
      task_name: "Card Task",
      notes: "Template card notes"
    )

    get timer_templates_path
    assert_response :success
    assert_select "p", text: /Template card notes/
  end

  test "should populate notes when selecting template in timer form" do
    template = @user.timer_templates.create!(
      name: "JS Template",
      task_name: "JS Task",
      notes: "Template notes for JavaScript test"
    )

    get new_timer_path
    assert_response :success
    
    # Check that template data includes notes
    assert_includes response.body, "Template notes for JavaScript test"
  end

  test "should handle empty notes in template" do
    template = @user.timer_templates.create!(
      name: "Empty Notes Template",
      task_name: "Empty Task",
      notes: ""
    )

    get timer_template_path(template)
    assert_response :success
    
    # Should not show notes section for empty notes
    assert_select "dt", text: "Notes", count: 0
  end

  test "should preserve line breaks in template notes" do
    multiline_notes = "Step 1: Prepare\nStep 2: Execute\n\nStep 3: Review"
    template = @user.timer_templates.create!(
      name: "Multiline Template",
      task_name: "Multiline Task",
      notes: multiline_notes
    )

    get timer_template_path(template)
    assert_response :success
    
    # Check that whitespace-pre-wrap class is present for line break preservation
    assert_select "p.whitespace-pre-wrap"
    # And that the notes content is displayed (even if whitespace is normalized in tests)
    assert_includes response.body, "Step 1: Prepare"
    assert_includes response.body, "Step 3: Review"
  end

  test "should escape HTML in template notes" do
    html_notes = "<script>alert('xss')</script><b>Bold text</b>"
    template = @user.timer_templates.create!(
      name: "HTML Template",
      task_name: "HTML Task",
      notes: html_notes
    )

    get timer_template_path(template)
    assert_response :success
    
    # Should escape HTML - the script tag should not be executable
    assert_not_includes response.body, "alert('xss')"
    # But the escaped HTML should be visible in the notes section
    assert_select "p.whitespace-pre-wrap", text: html_notes
  end

  test "should include notes when creating timer from template via form" do
    template = @user.timer_templates.create!(
      name: "Form Template",
      task_name: "Form Task",
      timer_type: "stopwatch",
      notes: "Notes from template form test"
    )

    # This simulates what happens when JavaScript populates the form
    post timers_path, params: {
      timer: {
        task_name: template.task_name,
        timer_type: template.timer_type,
        notes: template.notes
      }
    }

    timer = Timer.last
    assert_equal "Notes from template form test", timer.notes
  end

  test "should include notes when creating timer via direct template action" do
    template = @user.timer_templates.create!(
      name: "Direct Template",
      task_name: "Direct Task",
      timer_type: "countdown",
      target_duration: 1500,
      notes: "Direct action template notes"
    )

    post create_timer_timer_template_path(template)
    
    timer = Timer.last
    assert_equal "Direct action template notes", timer.notes
    assert_equal template.task_name, timer.task_name
  end

  test "should validate template notes on template creation" do
    # Test with valid notes
    assert_difference('TimerTemplate.count') do
      post timer_templates_path, params: {
        timer_template: {
          name: "Valid Template",
          task_name: "Valid Task",
          notes: "Valid notes"
        }
      }
    end

    # Test with notes too long
    assert_no_difference('TimerTemplate.count') do
      post timer_templates_path, params: {
        timer_template: {
          name: "Invalid Template",
          task_name: "Invalid Task",
          notes: "a" * 2001
        }
      }
    end
  end
end