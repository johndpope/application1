require 'test_helper'

class PhoneCallsControllerTest < ActionController::TestCase
  setup do
    @phone_call = phone_calls(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:phone_calls)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create phone_call" do
    assert_difference('PhoneCall.count') do
      post :create, phone_call: {  }
    end

    assert_redirected_to phone_call_path(assigns(:phone_call))
  end

  test "should show phone_call" do
    get :show, id: @phone_call
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @phone_call
    assert_response :success
  end

  test "should update phone_call" do
    patch :update, id: @phone_call, phone_call: {  }
    assert_redirected_to phone_call_path(assigns(:phone_call))
  end

  test "should destroy phone_call" do
    assert_difference('PhoneCall.count', -1) do
      delete :destroy, id: @phone_call
    end

    assert_redirected_to phone_calls_path
  end
end
