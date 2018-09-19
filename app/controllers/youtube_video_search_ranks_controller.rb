class YoutubeVideoSearchRanksController < ApplicationController
  before_action :set_youtube_video_search_rank, only: [:show]
  DEFAULT_LIMIT = 25

  def index
    params[:limit] = DEFAULT_LIMIT unless params[:limit].present?

		if params[:filter].present?
			params[:filter][:order] = 'created_at' unless params[:filter][:order].present?
			params[:filter][:order_type] = 'desc' unless params[:filter][:order_type].present?
		else
			params[:filter] = { order: 'created_at', order_type: 'desc' }
		end
		order_by = params[:filter][:order]
    order_by = "page" if order_by == "page_number"

    @youtube_video_search_ranks = YoutubeVideoSearchRank.joins(
      "LEFT OUTER JOIN youtube_video_search_phrases ON youtube_video_search_phrases.id = youtube_video_search_ranks.youtube_video_search_phrase_id
      LEFT OUTER JOIN youtube_videos ON youtube_videos.id = youtube_video_search_phrases.youtube_video_id
      LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id
      LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id
      LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id
      LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id")
      .by_id(params[:id])
      .by_email_account_id(params[:email_account_id])
      .by_page(params[:page_number])
      .by_search_type(params[:search_type])
      .by_result_type(params[:result_type])
      .by_youtube_video_id(params[:youtube_video_id])
      .page(params[:page]).per(params[:limit])
      .order(order_by + ' ' + params[:filter][:order_type] + " NULLS LAST, youtube_video_search_ranks.created_at DESC")
  end

  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_youtube_video_search_rank
      @youtube_video_search_rank = YoutubeVideoSearchRank.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def youtube_video_search_rank_params
      params.require(:youtube_video_search_rank).permit!
    end
end
