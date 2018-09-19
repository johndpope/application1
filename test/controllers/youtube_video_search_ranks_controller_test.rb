require 'test_helper'

class YoutubeVideoSearchRanksControllerTest < ActionController::TestCase
  setup do
    @youtube_video_search_rank = youtube_video_search_ranks(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:youtube_video_search_ranks)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create youtube_video_search_rank" do
    assert_difference('YoutubeVideoSearchRank.count') do
      post :create, youtube_video_search_rank: {  }
    end

    assert_redirected_to youtube_video_search_rank_path(assigns(:youtube_video_search_rank))
  end

  test "should show youtube_video_search_rank" do
    get :show, id: @youtube_video_search_rank
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @youtube_video_search_rank
    assert_response :success
  end

  test "should update youtube_video_search_rank" do
    patch :update, id: @youtube_video_search_rank, youtube_video_search_rank: {  }
    assert_redirected_to youtube_video_search_rank_path(assigns(:youtube_video_search_rank))
  end

  test "should destroy youtube_video_search_rank" do
    assert_difference('YoutubeVideoSearchRank.count', -1) do
      delete :destroy, id: @youtube_video_search_rank
    end

    assert_redirected_to youtube_video_search_ranks_path
  end
end
