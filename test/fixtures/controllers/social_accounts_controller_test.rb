require 'test_helper'

class SocialAccountsControllerTest < ActionController::TestCase
  setup do
    @social_account = social_accounts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:social_accounts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create social_account" do
    assert_difference('SocialAccount.count') do
      post :create, social_account: {  }
    end

    assert_redirected_to social_account_path(assigns(:social_account))
  end

  test "should show social_account" do
    get :show, id: @social_account
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @social_account
    assert_response :success
  end

  test "should update social_account" do
    patch :update, id: @social_account, social_account: {  }
    assert_redirected_to social_account_path(assigns(:social_account))
  end

  test "should destroy social_account" do
    assert_difference('SocialAccount.count', -1) do
      delete :destroy, id: @social_account
    end

    assert_redirected_to social_accounts_path
  end
end
