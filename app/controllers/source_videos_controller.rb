class SourceVideosController < ApplicationController
	include Templates::AaeProjectTextConcern
	include SourceVideosHelper

	SOURCE_VIDEO_LIMIT = 25
	SOURCE_VIDEO_TITLE_SEPARATOR = '<sep/>'

	before_action :set_client, only: [:new, :edit, :create, :update, :clone]
	before_action :set_dynamic_texts_settings, only:[:new, :edit, :create, :update]
	before_action :set_source_video, only: [:edit, :update, :destroy]
	before_action :set_aae_project_text_types, only: [:new, :edit, :create, :update, :add_aae_project_dynamic_text]
	before_action :set_grouped_dynamic_texts, only: %w(new edit create update)

	def download
		source_video = SourceVideo.find(params[:id])
		send_file(source_video.video.path, type: source_video.video_content_type)
	end

	def show_thumbnail
		source_video = SourceVideo.find(params[:id])
		send_file(source_video.thumbnail.path, type: source_video.thumbnail_content_type)
	end

	# TODO remove after code refactoring
	def remove_thumbnail
		source_video = SourceVideo.find(params[:id])
		source_video.thumbnail.destroy
		source_video.update({ thumbnail_content_type: nil, thumbnail_file_size: nil, thumbnail_updated_at: nil })
		redirect_to admin_source_video_path(source_video), notice: 'You have successfully removed thumbnail'
	end

	def index
		@source_videos = SourceVideo.order(created_at: :desc).page(params[:page]).per(SOURCE_VIDEO_LIMIT)
	end

	def create
		@source_video = SourceVideo.new(source_video_params)
		@grouped_dynamic_texts = {}
		if @source_video.save
			render "source_videos/create"
		else
			render partial: 'source_videos/modal_dialog'
		end
	end

  def clone
    source = SourceVideo.find(params[:id])
		target = source.donor.present? ? source.donor : source
		target.product_id = source.product_id
    text_strings = target.templates_aae_project_dynamic_texts
    tags = target.tag_list.to_a.join(",")
    wordings = target.wordings
    video_path = target.video.try(:path) if target.video.exists?
    thumbnail_path = target.thumbnail.try(:path) if target.thumbnail.exists?
    @source_video = SourceVideo.new
    @source_video.attributes = target.attributes
    @source_video.updated_at = nil
    @source_video.created_at = nil
    @source_video.id = nil
    @source_video.video = nil
    @source_video.video_file_name = nil
    @source_video.video_content_type = nil
    @source_video.video_file_size = nil
    @source_video.video_updated_at = nil
    @source_video.thumbnail_file_name = nil
    @source_video.thumbnail_content_type = nil
    @source_video.thumbnail_file_size = nil
    @source_video.thumbnail_updated_at = nil
    @source_video.thumbnail = nil
    @source_video.custom_title = @source_video.custom_title + " (Clone)"
		@source_video.ready_for_production = false
    @source_video.video_duration = nil
		if @source_video.save
      @source_video.tag_list = tags
      if thumbnail_path.present?
        file = File.new(thumbnail_path)
        @source_video.thumbnail = file
        @source_video.save
        file.close
      end
      if video_path.present? && params[:with_video] == "true"
        begin
          file = File.new(video_path)
          @source_video.video = file
          @source_video.save
          file.close
        end
      end
      text_strings.each do |text_string|
        begin
          text_string_clone = text_string.dup
          text_string_clone.subject_video_id = @source_video.id
          text_string_clone.save
        end
      end
      wordings.each do |wording|
        wording_clone = wording.dup
        wording_clone.resource_id = @source_video.id
        wording_clone.save
      end
		end
    render "source_videos/create"
  end

	def new
		@source_video = SourceVideo.new
		@donor_source_video = nil
		@donor_client = nil
		@grouped_dynamic_texts = {}
	end

	def edit
		@location_json = loc_json(@source_video)
		@donor_source_video = @client.client_donor_source_videos.where(recipient_source_video_id: @source_video.id).first.try(:source_video)
	end

	def update
		if @source_video.update_attributes(source_video_params)
			render "source_videos/update"
		else
			render partial: 'source_videos/modal_dialog'
		end
	end

	def destroy
		@source_video.destroy!
	end

	private
		def source_video_params
			params.require(:source_video).permit(:id,
				:custom_title,
				:video,
				:thumbnail,
				:product_id,
				:ready_for_production,
				:tag_list,
				:is_virtual,
				:use_only_sv_specific_dyn_text_strings,
				:notes,
				:subject_title_components_csv,
				:country_id,
				:region1_id,
				:region2_id,
				:locality_id,
        wordings_attributes: [:id, :name, :resource_id, :resource_type, :source, :_destroy],
				templates_aae_project_dynamic_texts_attributes: [:id, :value, :text_type, :project_type, :_destroy])
		end

		def set_client
			@client = Client.find(params[:client_id])
		end

		def set_source_video
			@source_video = SourceVideo.find(params[:id])
		end

		def set_grouped_dynamic_texts
			@grouped_dynamic_texts = (defined?(@source_video)).nil? ? {} : @source_video.templates_aae_project_dynamic_texts.group_by(&:text_type)
		end

		def set_dynamic_texts_settings
			@dynamic_text_settings = {
				general:{
					video_subject:{limit: 100},
				},
				collage:{
					collage_quote:{limit: 80, min_items_count: 10},
					collage_call_to_action:{limit: 30, min_items_count: 10}
				},
				summary_points:{
					sum_points_point_text:{limit: 100, min_items_count: 6}
				},
				social_networks:{
					social_networks_call_to_action:{limit: 50}
				},
				ending:{
					ending_tagline:{limit: 70}
				},
				transition:{
					transition_client_quote:{limit: 70}
				}
			}
		end
	end
