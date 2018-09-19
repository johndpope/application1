class YoutubeVideoSearchPhrasesController < ApplicationController
  skip_before_filter :authenticate_admin_user!, :only => [:set_rank]
  skip_before_filter :verify_authenticity_token, :only => [:set_rank]
  before_action :set_youtube_video_search_phrase, only: [:edit, :update, :destroy, :set_rank]

	def index
		@youtube_video_search_phrases = YoutubeVideoSearchPhrase.where(youtube_video_id: params[:youtube_video_id])
	end

	def new
		@youtube_video_search_phrase = YoutubeVideoSearchPhrase.new(youtube_video_id: params[:youtube_video_id])
    render :edit, locals: {youtube_video_search_phrase: @youtube_video_search_phrase}
	end

  def edit
    render :edit, locals: {youtube_video_search_phrase: @youtube_video_search_phrase}
  end

  def update
    if @youtube_video_search_phrase.update_attributes(youtube_video_search_phrase_params)
      render :update, locals: {youtube_video_search_phrase: @youtube_video_search_phrase}
    else
      render :edit, locals: {youtube_video_search_phrase: @youtube_video_search_phrase}
    end
  end

	def create
		@youtube_video_search_phrase = YoutubeVideoSearchPhrase.new(youtube_video_search_phrase_params)
    if @youtube_video_search_phrase.save
      render :create, locals: {youtube_video_search_phrase: @youtube_video_search_phrase}
    else
      render :new, locals: {youtube_video_search_phrase: @youtube_video_search_phrase}
    end
	end

	def destroy
		@youtube_video_search_phrase.destroy
    render :destroy, locals: {youtube_video_search_phrase: @youtube_video_search_phrase}
	end

  def set_rank
    response = {status: 200}
    if params[:file].present? && params[:file].try(:tempfile).present?
      YoutubeVideoSearchRank.where(search_type: YoutubeVideoSearchRank.search_type.find_value(params[:search_type]).value, youtube_video_search_phrase_id: @youtube_video_search_phrase.id).update_all(current: false)
      params[:result_type] = YoutubeVideoSearchRank.result_type.find_value(:regular) unless params[:result_type].present?
      if !params[:youtube_video_string_id].present?
        #regular
        youtube_video_search_rank = YoutubeVideoSearchRank.new(page: params[:page], per_page: params[:per_page], position: params[:position], in_box_position: params[:in_box_position], search_type: params[:search_type], result_type: params[:result_type], current: true, youtube_video_search_phrase_id: @youtube_video_search_phrase.id)
        if YoutubeVideoSearchRank.search_type.find_value(params[:search_type]).value == YoutubeVideoSearchRank.search_type.find_value(:youtube).value && youtube_video_search_rank.position.to_i > 0
          inc = (youtube_video_search_rank.position.to_i % youtube_video_search_rank.per_page == 0) ? 0 : 1
          youtube_video_search_rank.page = youtube_video_search_rank.position.to_i / youtube_video_search_rank.per_page + inc
          youtube_video_search_rank.position = youtube_video_search_rank.position.to_i - (youtube_video_search_rank.page - 1) * youtube_video_search_rank.per_page
        end
        youtube_video_search_rank.rank = (youtube_video_search_rank.position.present? && youtube_video_search_rank.position.to_i > 0) ? ((youtube_video_search_rank.page - 1) * youtube_video_search_rank.per_page + youtube_video_search_rank.position) : nil
        youtube_video_search_rank.screenshot = params[:file].tempfile
        extension = Rack::Mime::MIME_TYPES.invert[youtube_video_search_rank.screenshot_content_type]
        youtube_video_search_rank.screenshot_file_name = File.basename("yvsph_" + @youtube_video_search_phrase.id.to_s)[0..-1] + extension
        response = {status: 500} unless youtube_video_search_rank.save
      else
        #video_box
        youtube_video_string_ids = params[:youtube_video_string_id].split(",").map(&:strip)
        youtube_videos = YoutubeVideo.where(youtube_video_id: youtube_video_string_ids)
        if youtube_videos.present?
          youtube_videos.each do |youtube_video|
            index_in_box = youtube_video_string_ids.index(youtube_video.youtube_video_id)
            if youtube_video.id == @youtube_video_search_phrase.youtube_video_id
              ##video_box with current video
              # youtube_video_search_rank = YoutubeVideoSearchRank.new(page: params[:page], per_page: params[:per_page], position: params[:position], search_type: params[:search_type], result_type: params[:result_type], current: true, youtube_video_search_phrase_id: @youtube_video_search_phrase.id)
              # youtube_video_search_rank.rank = youtube_video_search_rank.position.present? && youtube_video_search_rank.position.to_i > 0 ? (youtube_video_search_rank.page - 1) * youtube_video_search_rank.per_page + youtube_video_search_rank.position : nil
              # youtube_video_search_rank.screenshot = params[:file].tempfile
              # extension = Rack::Mime::MIME_TYPES.invert[youtube_video_search_rank.screenshot_content_type]
              # youtube_video_search_rank.screenshot_file_name = File.basename("yvsph_" + @youtube_video_search_phrase.id.to_s)[0..-1] + extension
              # youtube_video_search_rank.in_box_position = index_in_box + 1 if index_in_box.present?
              # response = {status: 500} unless youtube_video_search_rank.save
            else
              #video_box with other our videos
              yvsp = YoutubeVideoSearchPhrase.where(phrase: @youtube_video_search_phrase.phrase, disabled: true, unexpected: true, youtube_video_id: youtube_video.id).first_or_initialize
              yvsp.save
              youtube_video_search_rank = YoutubeVideoSearchRank.new(page: params[:page], per_page: params[:per_page], position: params[:position], search_type: params[:search_type], result_type: params[:result_type], current: true, youtube_video_search_phrase_id: yvsp.id)
              youtube_video_search_rank.rank = youtube_video_search_rank.position.present? && youtube_video_search_rank.position.to_i > 0 ? (youtube_video_search_rank.page - 1) * youtube_video_search_rank.per_page + youtube_video_search_rank.position : nil
              youtube_video_search_rank.screenshot = params[:file].tempfile
              extension = Rack::Mime::MIME_TYPES.invert[youtube_video_search_rank.screenshot_content_type]
              youtube_video_search_rank.screenshot_file_name = File.basename("yvsph_" + yvsp.id.to_s)[0..-1] + extension
              youtube_video_search_rank.in_box_position = index_in_box + 1 if index_in_box.present?
              response = {status: 500} unless youtube_video_search_rank.save
            end
          end
        else
          #video_box without our videos
          yvsp = YoutubeVideoSearchPhrase.where(phrase: @youtube_video_search_phrase.phrase, disabled: true, unexpected: true, email_account_id: @youtube_video_search_phrase.youtube_video.youtube_channel.google_account.email_account.id).first_or_initialize
          yvsp.save
          youtube_video_search_rank = YoutubeVideoSearchRank.new(page: params[:page], per_page: params[:per_page], position: params[:position], in_box_position: 0, search_type: params[:search_type], result_type: params[:result_type], current: true, youtube_video_search_phrase_id: yvsp.id)
          youtube_video_search_rank.screenshot = params[:file].tempfile
          extension = Rack::Mime::MIME_TYPES.invert[youtube_video_search_rank.screenshot_content_type]
          youtube_video_search_rank.screenshot_file_name = File.basename("yvsph_" + yvsp.id.to_s)[0..-1] + extension
          if YoutubeVideoSearchRank.result_type.find_value(params[:result_type]).try(:value) == YoutubeVideoSearchRank.result_type.find_value(:images_box).value && youtube_video_search_rank.in_box_position == 0
            youtube_video_search_rank.rank = nil
          end
          response = {status: 500} unless youtube_video_search_rank.save
        end
      end
      %x(rm -rf #{params[:file].tempfile.path})
    else
      response = {status: 500}
    end
    render json: response, status: response[:status]
  end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_youtube_video_search_phrase
			@youtube_video_search_phrase = YoutubeVideoSearchPhrase.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def youtube_video_search_phrase_params
			prms = params.require(:youtube_video_search_phrase).permit!
      prms[:phrase] = prms[:phrase].strip
      prms
    end
end
