require 'test_helper'

class ReleasesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:releases)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create release" do
    assert_difference('Release.count') do
      post :create, :release => { }
    end

    assert_redirected_to release_path(assigns(:release))
  end

  test "should show release" do
    get :show, :id => releases(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => releases(:one).to_param
    assert_response :success
  end

  test "should update release" do
    put :update, :id => releases(:one).to_param, :release => { }
    assert_redirected_to release_path(assigns(:release))
  end

  test "should destroy release" do
    assert_difference('Release.count', -1) do
      delete :destroy, :id => releases(:one).to_param
    end

    assert_redirected_to releases_path
  end
end
