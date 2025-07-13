require "test_helper"

class TimerLifecycleTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    sign_in_user
  end

  test "complete timer lifecycle: create, start, pause, resume, stop" do
    # Create timer
    assert_difference "Timer.count", 1 do
      post timers_path, params: {
        timer: { task_name: "Lifecycle test", tags: "test, lifecycle" }
      }
    end

    timer = Timer.last
    assert_equal "stopped", timer.status
    assert_equal @user.id, timer.user_id

    # Start timer
    patch start_timer_path(timer)
    assert_redirected_to timers_path

    timer.reload
    assert_equal "running", timer.status
    assert_not_nil timer.start_time

    # Pause timer
    travel 30.seconds do
      patch pause_timer_path(timer)
      timer.reload
      assert_equal "paused", timer.status
      assert timer.duration > 0
    end

    # Resume timer
    patch resume_timer_path(timer)
    timer.reload
    assert_equal "running", timer.status

    # Stop timer
    travel 45.seconds do
      patch stop_timer_path(timer)
      timer.reload
      assert_equal "stopped", timer.status
      assert timer.duration > 0
    end
  end

  test "timer validation errors" do
    # Try to create timer without task name
    assert_no_difference "Timer.count" do
      post timers_path, params: {
        timer: { task_name: "" }
      }
    end
    assert_response :unprocessable_entity
    assert_match /Task name can&#39;t be blank/, response.body
  end

  test "timer CRUD operations" do
    # Create
    post timers_path, params: {
      timer: { task_name: "CRUD Test", tags: "crud" }
    }
    timer = Timer.last

    # Read
    get timer_path(timer)
    assert_response :success

    # Update
    patch timer_path(timer), params: {
      timer: { task_name: "Updated CRUD Test", tags: "updated, crud" }
    }
    timer.reload
    assert_equal "Updated CRUD Test", timer.task_name
    assert_equal "updated, crud", timer[:tags]

    # Delete
    assert_difference "Timer.count", -1 do
      delete timer_path(timer)
    end
  end

  test "multiple active timers" do
    timer1 = create_timer("Task 1")
    timer2 = create_timer("Task 2")

    # Start both
    patch start_timer_path(timer1)
    patch start_timer_path(timer2)

    [timer1, timer2].each(&:reload)
    assert_equal "running", timer1.status
    assert_equal "running", timer2.status

    # Manage independently
    patch pause_timer_path(timer1)
    patch stop_timer_path(timer2)

    [timer1, timer2].each(&:reload)
    assert_equal "paused", timer1.status
    assert_equal "stopped", timer2.status
  end

  test "state transition error handling" do
    timer = create_timer("Error test")

    # Try invalid transitions
    patch pause_timer_path(timer)
    follow_redirect!
    assert_match /not running/, flash[:alert]

    patch resume_timer_path(timer)
    follow_redirect!
    assert_match /not paused/, flash[:alert]

    patch stop_timer_path(timer)
    follow_redirect!
    assert_match /not active/, flash[:alert]
  end

  test "timer navigation and page rendering" do
    timer = create_timer("Navigation test")

    # Home page (timers)
    get root_path
    assert_response :success
    assert_select "a[href='#{new_timer_path}']"

    # Timers index
    get timers_path
    assert_response :success
    assert_select "a[href='#{new_timer_path}']"

    # New timer form
    get new_timer_path
    assert_response :success
    assert_select "form[action='#{timers_path}']"

    # Timer show
    get timer_path(timer)
    assert_response :success

    # Timer edit
    get edit_timer_path(timer)
    assert_response :success
    assert_select "form[action='#{timer_path(timer)}']"
  end

  private

  def sign_in_user
    # Use the session controller to sign in properly
    post session_url, params: { 
      email_address: @user.email_address, 
      password: "password" 
    }
    # Don't follow the redirect here, just ensure we're signed in
    assert_response :redirect
  end

  def create_timer(name)
    @user.timers.create!(task_name: name, status: "stopped")
  end

  def travel(duration, &block)
    travel_to Time.current + duration, &block
  end
end