require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get twitter_signin" do
    get :twitter_signin
    assert_response :success
  end

end
