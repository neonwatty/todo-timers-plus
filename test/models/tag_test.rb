require "test_helper"

class TagTest < ActiveSupport::TestCase
  def setup
    @tag = tags(:work)
  end

  test "should be valid" do
    assert @tag.valid?
  end

  test "name should be present" do
    @tag.name = "   "
    assert_not @tag.valid?
  end

  test "name should be unique" do
    duplicate_tag = @tag.dup
    duplicate_tag.name = @tag.name.upcase
    @tag.save
    assert_not duplicate_tag.valid?
  end

  test "name should be saved as lowercase" do
    mixed_case_name = "WorkProject"
    @tag.name = mixed_case_name
    @tag.save
    assert_equal mixed_case_name.downcase, @tag.reload.name
  end

  test "should have and belong to many timers" do
    assert_respond_to @tag, :timers
  end

  test "should have and belong to many timer_tags" do
    assert_respond_to @tag, :timer_tags
  end

  test "should have many users through timers" do
    assert_respond_to @tag, :users
  end

  test "should not destroy tag if associated with timers" do
    user = users(:one)
    timer = user.timers.create!(task_name: "Test Timer")
    timer.tags << @tag
    
    assert_no_difference 'Tag.count' do
      @tag.destroy
    end
  end

  test "color should have default value" do
    tag = Tag.new(name: "new_tag")
    tag.save
    assert_not_nil tag.color
  end

  test "find_or_create_by_names should create new tags" do
    tag_names = ["existing", "new1", "new2"]
    
    # Create one existing tag
    Tag.create!(name: "existing")
    
    assert_difference 'Tag.count', 2 do
      tags = Tag.find_or_create_by_names(tag_names)
      assert_equal 3, tags.count
      assert tags.all? { |t| tag_names.include?(t.name) }
    end
  end

  test "find_or_create_by_names should find existing tags" do
    # Use existing fixtures
    tag_names = ["work", "project", "meeting"]
    
    assert_no_difference 'Tag.count' do
      tags = Tag.find_or_create_by_names(tag_names)
      assert_equal 3, tags.count
      assert tags.all? { |t| tag_names.include?(t.name) }
    end
  end

  test "find_or_create_by_names should handle empty array" do
    tags = Tag.find_or_create_by_names([])
    assert_empty tags
  end

  test "find_or_create_by_names should handle nil" do
    tags = Tag.find_or_create_by_names(nil)
    assert_empty tags
  end

  test "find_or_create_by_names should strip whitespace" do
    tag_names = [" work ", "project  ", "  meeting"]
    
    assert_no_difference 'Tag.count' do
      tags = Tag.find_or_create_by_names(tag_names)
      assert_equal 3, tags.count
      assert tags.all? { |t| ["work", "project", "meeting"].include?(t.name) }
    end
  end

  test "should validate color format if implemented" do
    # This test is a placeholder for when color validation is added
    valid_colors = %w[blue green red purple orange yellow]
    valid_colors.each do |color|
      @tag.color = color
      assert @tag.valid?, "#{color} should be valid"
    end
  end
end
