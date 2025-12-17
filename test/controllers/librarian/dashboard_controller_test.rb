require "test_helper"

class Librarian::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get librarian_dashboard_index_url
    assert_response :success
  end
end
