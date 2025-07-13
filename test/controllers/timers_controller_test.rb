require "test_helper"

class TimersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @timer = timers(:running_timer)
    sign_in_as(@user)
  end

  test "should get index" do
    get timers_url
    assert_response :success
    assert_select "h2", "Quick Start Timer"
    assert_select "h3", "All Timers"
  end

  test "should get new" do
    get new_timer_url
    assert_response :success
    assert_select "form"
  end

  test "should create timer" do
    assert_difference("Timer.count") do
      post timers_url, params: { 
        timer: { 
          task_name: "New Test Timer",
          tags: "test, development"
        } 
      }
    end

    timer = Timer.last
    assert_redirected_to timer_url(timer)
    assert_equal "Timer was successfully created.", flash[:notice]
    assert_equal "test, development", timer[:tags]
    assert_equal ["test", "development"], timer.parse_tags
  end

  test "should create timer with notes" do
    assert_difference("Timer.count") do
      post timers_url, params: { 
        timer: { 
          task_name: "Timer with Notes",
          notes: "This is a test note"
        } 
      }
    end

    timer = Timer.last
    assert_redirected_to timer_url(timer)
    assert_equal "This is a test note", timer.notes
  end

  test "should not create timer with invalid params" do
    assert_no_difference("Timer.count") do
      post timers_url, params: { 
        timer: { 
          task_name: "",
          tags: "test"
        } 
      }
    end

    assert_response :unprocessable_entity
  end

  test "should save timer as template when requested" do
    assert_difference('Timer.count') do
      assert_difference('TimerTemplate.count') do
        post timers_url, params: {
          timer: {
            task_name: "Template Task",
            timer_type: "stopwatch",
            tags: "template, test"
          },
          save_as_template: "1"
        }
      end
    end

    template = TimerTemplate.last
    assert_equal "Template Task Template", template.name
    assert_equal "Template Task", template.task_name
    assert_equal "stopwatch", template.timer_type
    assert_equal "template, test", template.tags
  end

  test "should not save timer as template when not requested" do
    assert_difference('Timer.count') do
      assert_no_difference('TimerTemplate.count') do
        post timers_url, params: {
          timer: {
            task_name: "Regular Task",
            timer_type: "stopwatch"
          }
        }
      end
    end
  end

  test "should save countdown timer as template with duration" do
    assert_difference('Timer.count') do
      assert_difference('TimerTemplate.count') do
        post timers_url, params: {
          timer: {
            task_name: "Countdown Task",
            timer_type: "countdown",
            duration_hours: "0",
            duration_minutes: "25",
            duration_seconds: "0"
          },
          save_as_template: "1"
        }
      end
    end

    timer = Timer.last
    template = TimerTemplate.last
    
    assert_equal timer.target_duration, template.target_duration
    assert_equal 1500, template.target_duration # 25 minutes
  end

  test "should load templates for new timer form" do
    get new_timer_url
    assert_response :success
    # Test that the form loads properly - template loading is tested in integration tests
  end

  test "should show timer" do
    get timer_url(@timer)
    assert_response :success
    assert_select "h1", @timer.task_name
  end

  test "should get edit" do
    get edit_timer_url(@timer)
    assert_response :success
    assert_select "form"
  end

  test "should update timer" do
    patch timer_url(@timer), params: { 
      timer: { 
        task_name: "Updated Timer Name" 
      } 
    }
    assert_redirected_to timer_url(@timer)
    @timer.reload
    assert_equal "Updated Timer Name", @timer.task_name
    assert_equal "Timer was successfully updated.", flash[:notice]
  end

  test "should update timer notes" do
    patch timer_url(@timer), params: { 
      timer: { 
        notes: "Updated notes content" 
      } 
    }
    assert_redirected_to timer_url(@timer)
    @timer.reload
    assert_equal "Updated notes content", @timer.notes
  end

  test "should not update timer with invalid params" do
    patch timer_url(@timer), params: { 
      timer: { 
        task_name: "" 
      } 
    }
    assert_response :unprocessable_entity
  end

  test "should destroy timer" do
    assert_difference("Timer.count", -1) do
      delete timer_url(@timer)
    end

    assert_redirected_to timers_url
    assert_equal "Timer was successfully deleted.", flash[:notice]
  end

  test "should start timer" do
    timer = @user.timers.create!(task_name: "Test Timer", status: "stopped")
    
    patch start_timer_url(timer)
    assert_redirected_to timers_url
    
    timer.reload
    assert_equal "running", timer.status
    assert_not_nil timer.start_time
  end

  test "should pause timer" do
    patch pause_timer_url(@timer)
    assert_redirected_to timers_url
    
    @timer.reload
    assert_equal "paused", @timer.status
  end

  test "should resume timer" do
    timer = timers(:paused_timer)
    
    patch resume_timer_url(timer)
    assert_redirected_to timers_url
    
    timer.reload
    assert_equal "running", timer.status
  end

  test "should stop timer" do
    patch stop_timer_url(@timer)
    assert_redirected_to timers_url
    
    @timer.reload
    assert_equal "stopped", @timer.status
    assert_not_nil @timer.end_time
  end

  test "should not access other user's timer" do
    other_user = users(:two)
    other_timer = timers(:stopped_timer) # belongs to user two
    
    get timer_url(other_timer)
    assert_response :not_found
  end

  test "should require authentication" do
    sign_out
    
    get timers_url
    assert_redirected_to new_session_url
  end
  
  test "should quick start a stopwatch timer" do
    assert_difference("Timer.count") do
      post quick_start_timers_url, params: { task_name: "Quick task", timer_type: "stopwatch" }, as: :turbo_stream
    end
    
    timer = Timer.last
    assert_equal "Quick task", timer.task_name
    assert_equal "stopwatch", timer.timer_type
    assert_equal "running", timer.status
    assert_not_nil timer.start_time
    
    assert_response :success
    assert_match /Timer started!/, response.body
  end
  
  test "should quick start a countdown timer" do
    assert_difference("Timer.count") do
      post quick_start_timers_url, params: { 
        task_name: "Countdown task", 
        timer_type: "countdown",
        duration_minutes: "25"
      }, as: :turbo_stream
    end
    
    timer = Timer.last
    assert_equal "Countdown task", timer.task_name
    assert_equal "countdown", timer.timer_type
    assert_equal "running", timer.status
    assert_equal 1500, timer.target_duration
    assert_equal 1500, timer.remaining_duration
    
    assert_response :success
  end
  
  test "should quick start with tags" do
    post quick_start_timers_url, params: { 
      task_name: "Tagged task", 
      tags: "work, urgent"
    }, as: :turbo_stream
    
    timer = Timer.last
    assert_equal "work, urgent", timer[:tags]
  end
  
  test "should quick start with notes" do
    post quick_start_timers_url, params: { 
      task_name: "Task with notes", 
      notes: "Remember to check the API docs"
    }, as: :turbo_stream
    
    timer = Timer.last
    assert_equal "Remember to check the API docs", timer.notes
  end
  
  test "should quick start without duration for countdown timer" do
    post quick_start_timers_url, params: { 
      task_name: "Countdown without duration", 
      timer_type: "countdown"
    }, as: :turbo_stream
    
    timer = Timer.last
    assert_equal "countdown", timer.timer_type
    assert_nil timer.target_duration
    assert_nil timer.remaining_duration
  end

end