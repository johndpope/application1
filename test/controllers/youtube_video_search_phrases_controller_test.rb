require 'test_helper'

class YoutubeVideoSearchPhrasesControllerTest < ActionController::TestCase
  setup do
    @youtube_video_search_phrase = youtube_video_search_phrases(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:youtube_video_search_phrases)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create youtube_video_search_phrase" do
    assert_difference('YoutubeVideoSearchPhrase.count') do
      post :create, youtube_video_search_phrase: {  }
    end

    assert_redirected_to youtube_video_search_phrase_path(assigns(:youtube_video_search_phrase))
  end

  test "should show youtube_video_search_phrase" do
    get :show, id: @youtube_video_search_phrase
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @youtube_video_search_phrase
    assert_response :success
  end

  test "should update youtube_video_search_phrase" do
    patch :update, id: @youtube_video_search_phrase, youtube_video_search_phrase: {  }
    assert_redirected_to youtube_video_search_phrase_path(assigns(:youtube_video_search_phrase))
  end

  test "should destroy youtube_video_search_phrase" do
    assert_difference('YoutubeVideoSearchPhrase.count', -1) do
      delete :destroy, id: @youtube_video_search_phrase
    end

    assert_redirected_to youtube_video_search_phrases_path
  end
end
