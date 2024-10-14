require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get userhome" do
    get pages_userhome_url
    assert_response :success
  end
end
