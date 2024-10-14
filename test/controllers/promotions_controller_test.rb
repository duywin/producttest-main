require "test_helper"

class PromotionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get promotions_new_url
    assert_response :success
  end

  test "should get create" do
    get promotions_create_url
    assert_response :success
  end
end
