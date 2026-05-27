require "test_helper"

class TaskControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get task_index_url
    assert_response :success
  end

  test "should get create" do
    get task_create_url
    assert_response :success
  end
end
