require "test_helper"

class BorrowingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get borrowings_index_url
    assert_response :success
  end

  test "should get show" do
    get borrowings_show_url
    assert_response :success
  end

  test "should get return_book" do
    get borrowings_return_book_url
    assert_response :success
  end
end
