require 'test_helper'

class VideoMarketingCampaignFormsControllerTest < ActionController::TestCase
  setup do
    @video_marketing_campaign_form = video_marketing_campaign_forms(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:video_marketing_campaign_forms)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create video_marketing_campaign_form" do
    assert_difference('VideoMarketingCampaignForm.count') do
      post :create, video_marketing_campaign_form: {  }
    end

    assert_redirected_to video_marketing_campaign_form_path(assigns(:video_marketing_campaign_form))
  end

  test "should show video_marketing_campaign_form" do
    get :show, id: @video_marketing_campaign_form
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @video_marketing_campaign_form
    assert_response :success
  end

  test "should update video_marketing_campaign_form" do
    patch :update, id: @video_marketing_campaign_form, video_marketing_campaign_form: {  }
    assert_redirected_to video_marketing_campaign_form_path(assigns(:video_marketing_campaign_form))
  end

  test "should destroy video_marketing_campaign_form" do
    assert_difference('VideoMarketingCampaignForm.count', -1) do
      delete :destroy, id: @video_marketing_campaign_form
    end

    assert_redirected_to video_marketing_campaign_forms_path
  end
end
