require "test_helper"

class TimerTagsDisplayTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "timer tags should display correctly after creation" do
    # Create a timer with tags
    post timers_path, params: {
      timer: {
        task_name: "Test Timer with Tags",
        tags: "work, project, important"
      }
    }
    
    timer = Timer.last
    assert_equal "work, project, important", timer[:tags]
    
    # Follow the redirect to the timer show page
    follow_redirect!
    assert_response :success
    
    # Check that individual tags are displayed, not the raw association
    assert_select "span", text: "work"
    assert_select "span", text: "project" 
    assert_select "span", text: "important"
    
    # Make sure we don't see the raw ActiveRecord association string
    assert_not_includes response.body, "ActiveRecord_Associations_CollectionProxy"
    assert_not_includes response.body, "#<Tag::"
  end

  test "timer with tags should display correctly in index page" do
    # Create a timer with tags
    timer = @user.timers.create!(
      task_name: "Tagged Timer",
      tags: "test, display",
      status: "stopped"
    )
    
    get timers_path
    assert_response :success
    
    # Check that tags are displayed properly
    assert_select "span", text: "test"
    assert_select "span", text: "display"
    
    # Make sure we don't see raw association output
    assert_not_includes response.body, "ActiveRecord_Associations_CollectionProxy"
    assert_not_includes response.body, "#<Tag::"
  end

  test "timer json response should include parsed tags" do
    timer = @user.timers.create!(
      task_name: "JSON Test Timer",
      tags: "json, api, test",
      status: "stopped"
    )
    
    get timer_path(timer, format: :json)
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal ["json", "api", "test"], json_response["tags"]
  end
end