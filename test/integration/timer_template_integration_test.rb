require "test_helper"

class TimerTemplateIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @template = timer_templates(:one)
    sign_in_as @user
  end

  test "should display templates on new timer page" do
    get new_timer_path
    assert_response :success
    
    assert_select "h3", text: "Start from Template"
    assert_select "[data-template]", minimum: 1
  end

  test "should create timer from template" do
    assert_difference('Timer.count') do
      post create_timer_timer_template_path(@template)
    end
    
    timer = Timer.last
    assert_equal @template.task_name, timer.task_name
    assert_equal @template.timer_type, timer.timer_type
    assert_redirected_to timers_path
  end

  test "should increment template usage when creating timer from template" do
    original_count = @template.usage_count
    
    post create_timer_timer_template_path(@template)
    @template.reload
    
    assert_equal original_count + 1, @template.usage_count
    assert_not_nil @template.last_used_at
  end

  test "should save timer as template when checkbox is checked" do
    assert_difference('TimerTemplate.count') do
      post timers_path, params: {
        timer: {
          task_name: "New Task",
          timer_type: "stopwatch",
          tags: "test, integration"
        },
        save_as_template: "1"
      }
    end
    
    template = TimerTemplate.last
    assert_equal "New Task Template", template.name
    assert_equal "New Task", template.task_name
    assert_equal "stopwatch", template.timer_type
    assert_equal "test, integration", template.tags
  end

  test "should not save timer as template when checkbox is unchecked" do
    assert_no_difference('TimerTemplate.count') do
      post timers_path, params: {
        timer: {
          task_name: "New Task",
          timer_type: "stopwatch"
        }
      }
    end
  end

  test "should create template with countdown duration" do
    assert_difference('TimerTemplate.count') do
      post timer_templates_path, params: {
        timer_template: {
          name: "Pomodoro Template",
          task_name: "Focus Session",
          timer_type: "countdown",
          duration_hours: "0",
          duration_minutes: "25",
          duration_seconds: "0",
          tags: "focus, pomodoro"
        }
      }
    end
    
    template = TimerTemplate.last
    assert_equal "Pomodoro Template", template.name
    assert_equal "countdown", template.timer_type
    assert_equal 1500, template.target_duration # 25 minutes
  end

  test "should show template usage statistics" do
    get timer_template_path(@template)
    assert_response :success
    
    assert_select ".text-2xl", text: @template.usage_count.to_s
    assert_select "h1", text: @template.name
  end

  test "should update template" do
    patch timer_template_path(@template), params: {
      timer_template: {
        name: "Updated Template Name",
        task_name: "Updated Task"
      }
    }
    
    @template.reload
    assert_equal "Updated Template Name", @template.name
    assert_equal "Updated Task", @template.task_name
    assert_redirected_to timer_template_path(@template)
  end

  test "should delete template" do
    assert_difference('TimerTemplate.count', -1) do
      delete timer_template_path(@template)
    end
    
    assert_redirected_to timer_templates_path
  end

  test "should show templates index with statistics" do
    get timer_templates_path
    assert_response :success
    
    assert_select "h2", text: "Timer Templates"
    assert_select ".text-2xl", text: @user.timer_templates.count.to_s
  end

  test "should require authentication for template actions" do
    sign_out
    
    get timer_templates_path
    assert_redirected_to new_session_path
    
    get new_timer_template_path
    assert_redirected_to new_session_path
    
    post timer_templates_path, params: { timer_template: { name: "Test" } }
    assert_redirected_to new_session_path
  end

  test "should only show current user's templates" do
    other_user = users(:two)
    other_template = timer_templates(:two)
    
    get timer_templates_path
    assert_response :success
    
    # Should see own template name in the page
    assert_select "h4, h1", text: /#{@template.name}/
    
    # Should not see other user's template name
    assert_select "h4, h1", text: /#{other_template.name}/, count: 0
  end

  test "should not allow access to other user's templates" do
    other_template = timer_templates(:two)
    
    # Try to access other user's template
    get timer_template_path(other_template)
    # Either 404 Not Found or redirected away from the template
    assert_not_equal 200, response.status, "Should not be able to access other user's template"
  end

  test "should handle countdown timer creation from template correctly" do
    countdown_template = @user.timer_templates.create!(
      name: "25min Focus",
      timer_type: "countdown",
      target_duration: 1500,
      task_name: "Deep Work"
    )
    
    post create_timer_timer_template_path(countdown_template)
    
    timer = Timer.last
    assert_equal "countdown", timer.timer_type
    assert_equal 1500, timer.target_duration
    assert_equal 1500, timer.remaining_duration
  end

  test "should validate template creation with missing required fields" do
    post timer_templates_path, params: {
      timer_template: {
        name: "", # Missing required name
        timer_type: "countdown"
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".text-red-700", text: /can't be blank/
  end

  test "should validate countdown template requires duration" do
    post timer_templates_path, params: {
      timer_template: {
        name: "Test Countdown",
        timer_type: "countdown",
        duration_hours: "0",
        duration_minutes: "0", 
        duration_seconds: "0"
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".text-red-700", text: /can't be blank/
  end

  test "new timer form should display popular templates separately" do
    # Create templates with different usage counts
    popular_template = @user.timer_templates.create!(
      name: "Popular Template",
      timer_type: "stopwatch",
      usage_count: 10
    )
    
    get new_timer_path
    assert_response :success
    
    # Should show popular templates section if popular templates exist
    if @user.timer_templates.where("usage_count > 0").exists?
      assert_select "h4", text: "Popular Templates"
    end
    # The template should appear in the template selection area
    assert_select "button", text: /Popular Template/
  end

  private

  def sign_out
    delete session_path
  end
end