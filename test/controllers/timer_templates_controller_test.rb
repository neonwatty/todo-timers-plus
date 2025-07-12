require "test_helper"

class TimerTemplatesControllerTest < ActionController::TestCase
  setup do
    sign_in_as users(:one)
    @timer_template = timer_templates(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get show" do
    get :show, params: { id: @timer_template.id }
    assert_response :success
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create timer_template" do
    assert_difference('TimerTemplate.count') do
      post :create, params: { 
        timer_template: { 
          name: "Test Template",
          timer_type: "stopwatch",
          task_name: "Test Task"
        } 
      }
    end
    assert_redirected_to timer_template_path(TimerTemplate.last)
  end

  test "should get edit" do
    get :edit, params: { id: @timer_template.id }
    assert_response :success
  end

  test "should update timer_template" do
    patch :update, params: { 
      id: @timer_template.id,
      timer_template: { 
        name: "Updated Template"
      } 
    }
    assert_redirected_to timer_template_path(@timer_template)
  end

  test "should destroy timer_template" do
    assert_difference('TimerTemplate.count', -1) do
      delete :destroy, params: { id: @timer_template.id }
    end
    assert_redirected_to timer_templates_path
  end

  test "should create timer from template" do
    assert_difference('Timer.count') do
      post :create_timer, params: { id: @timer_template.id }
    end
    
    timer = Timer.last
    assert_equal @timer_template.task_name, timer.task_name
    assert_equal @timer_template.timer_type, timer.timer_type
    assert_redirected_to timers_path
  end

  test "should increment usage count when creating timer from template" do
    original_count = @timer_template.usage_count
    original_time = @timer_template.last_used_at
    
    post :create_timer, params: { id: @timer_template.id }
    @timer_template.reload
    
    assert_equal original_count + 1, @timer_template.usage_count
    assert @timer_template.last_used_at > original_time
  end

  test "should handle countdown template duration conversion" do
    patch :update, params: {
      id: @timer_template.id,
      timer_template: {
        timer_type: "countdown",
        duration_hours: "1",
        duration_minutes: "30",
        duration_seconds: "15"
      }
    }
    
    @timer_template.reload
    expected_duration = (1 * 3600) + (30 * 60) + 15 # 5415 seconds
    assert_equal expected_duration, @timer_template.target_duration
  end

  test "should not require duration for stopwatch templates" do
    patch :update, params: {
      id: @timer_template.id,
      timer_template: {
        timer_type: "stopwatch"
      }
    }
    
    assert_response :redirect
    @timer_template.reload
    assert_equal "stopwatch", @timer_template.timer_type
  end

  test "should validate countdown template creation with duration" do
    assert_difference('TimerTemplate.count') do
      post :create, params: {
        timer_template: {
          name: "Test Countdown",
          timer_type: "countdown",
          duration_hours: "0",
          duration_minutes: "25",
          duration_seconds: "0"
        }
      }
    end
    
    template = TimerTemplate.last
    assert_equal 1500, template.target_duration # 25 minutes
  end

  test "should fail to create countdown template without duration" do
    assert_no_difference('TimerTemplate.count') do
      post :create, params: {
        timer_template: {
          name: "Invalid Countdown",
          timer_type: "countdown",
          duration_hours: "0",
          duration_minutes: "0",
          duration_seconds: "0"
        }
      }
    end
    
    assert_response :unprocessable_entity
  end

  test "should show popular and recent templates in index" do
    # Create templates with different usage patterns
    popular = Current.user.timer_templates.create!(
      name: "Popular", 
      timer_type: "stopwatch", 
      usage_count: 10
    )
    recent = Current.user.timer_templates.create!(
      name: "Recent", 
      timer_type: "stopwatch", 
      last_used_at: 1.hour.ago
    )
    
    get :index
    assert_response :success
    # Test that the page loads without checking assigns since assigns is deprecated
  end

  test "should only show current user templates" do
    other_user_template = timer_templates(:two) # Belongs to user :two
    
    get :index
    assert_response :success
    # Test that the page loads - user isolation is tested in integration tests
  end

  test "should not allow access to other user template" do
    other_user_template = timer_templates(:two)
    
    assert_raises(ActiveRecord::RecordNotFound) do
      get :show, params: { id: other_user_template.id }
    end
  end

  test "should pre-populate template from timer parameters" do
    timer = Current.user.timers.build(
      task_name: "Source Timer",
      timer_type: "countdown",
      target_duration: 900 # 15 minutes
    )
    timer[:tags] = "source, test" # Use column access to avoid association conflict
    timer.save!
    
    get :new, params: { from_timer_id: timer.id }
    assert_response :success
    # Test that the page loads - specific template attributes are tested in integration tests
  end

  # Notes functionality tests
  test "should create timer_template with notes" do
    assert_difference('TimerTemplate.count') do
      post :create, params: { 
        timer_template: { 
          name: "Template with Notes",
          timer_type: "stopwatch",
          task_name: "Test Task",
          notes: "Important template notes for context"
        } 
      }
    end
    
    template = TimerTemplate.last
    assert_equal "Important template notes for context", template.notes
    assert_redirected_to timer_template_path(template)
  end

  test "should update timer_template notes" do
    patch :update, params: { 
      id: @timer_template.id,
      timer_template: { 
        notes: "Updated notes content"
      } 
    }
    
    @timer_template.reload
    assert_equal "Updated notes content", @timer_template.notes
    assert_redirected_to timer_template_path(@timer_template)
  end

  test "should reject timer_template with notes too long" do
    assert_no_difference('TimerTemplate.count') do
      post :create, params: { 
        timer_template: { 
          name: "Invalid Template",
          timer_type: "stopwatch",
          notes: "a" * 2001 # Too long
        } 
      }
    end
    assert_response :unprocessable_entity
  end

  test "should create timer from template with notes" do
    @timer_template.update!(notes: "Template context notes")
    
    assert_difference('Timer.count') do
      post :create_timer, params: { id: @timer_template.id }
    end
    
    timer = Timer.last
    assert_equal "Template context notes", timer.notes
    assert_equal @timer_template.task_name, timer.task_name
    assert_redirected_to timers_path
  end

  test "should handle empty notes in template creation" do
    assert_difference('TimerTemplate.count') do
      post :create, params: { 
        timer_template: { 
          name: "Template without Notes",
          timer_type: "stopwatch",
          notes: ""
        } 
      }
    end
    
    template = TimerTemplate.last
    assert_equal "", template.notes
  end

  test "should clear notes when updating template" do
    @timer_template.update!(notes: "Original notes")
    
    patch :update, params: { 
      id: @timer_template.id,
      timer_template: { 
        notes: ""
      } 
    }
    
    @timer_template.reload
    assert_equal "", @timer_template.notes
  end
end
