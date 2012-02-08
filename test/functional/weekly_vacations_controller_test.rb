require 'test_helper'

class WeeklyVacationsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:weekly_vacations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create weekly_vacation" do
    assert_difference('WeeklyVacation.count') do
      post :create, :weekly_vacation => { }
    end

    assert_redirected_to weekly_vacation_path(assigns(:weekly_vacation))
  end

  test "should show weekly_vacation" do
    get :show, :id => weekly_vacations(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => weekly_vacations(:one).to_param
    assert_response :success
  end

  test "should update weekly_vacation" do
    put :update, :id => weekly_vacations(:one).to_param, :weekly_vacation => { }
    assert_redirected_to weekly_vacation_path(assigns(:weekly_vacation))
  end

  test "should destroy weekly_vacation" do
    assert_difference('WeeklyVacation.count', -1) do
      delete :destroy, :id => weekly_vacations(:one).to_param
    end

    assert_redirected_to weekly_vacations_path
  end
end
