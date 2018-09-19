class Templates::AaeProjectDynamicTextsController < ApplicationController
  skip_before_filter :authenticate_admin_user!, :only => [:new, :edit, :create, :update, :destroy]
	before_action :set_dynamic_text, only: [:update, :destroy, :edit]

	def new
		@dynamic_text = Templates::AaeProjectDynamicText.new
		@dynamic_text.text_type = params[:text_type]
		@dynamic_text.project_type = params[:project_type]
		@dynamic_text.client_id = params[:client_id]
    @dynamic_text.video_marketing_campaign_form_id = params[:video_marketing_campaign_form_id]
	end

	def edit

	end

	def create
		@dynamic_text = Templates::AaeProjectDynamicText::create(dynamic_text_params)
		if @dynamic_text.save
			@dynamic_texts = []
			params[:values].to_a.compact.reject(&:blank?).each do |v|
				text_params = dynamic_text_params
				text_params[:value] = v
				dt = Templates::AaeProjectDynamicText::create(text_params)
				@dynamic_texts << dt
			end
			@dynamic_texts << @dynamic_text
			render locals: {text_type: @dynamic_texts.first.text_type,
				items_count: Templates::AaeProjectDynamicText.where(text_type: dynamic_text_params[:text_type], client_id: @dynamic_text.client.try(:id), video_marketing_campaign_form_id: @dynamic_text.video_marketing_campaign_form.try(:id)).size}
		else
			render partial: 'templates/aae_project_dynamic_texts/form_modal_dialog'
		end
	end

	def update
		if(@dynamic_text.update_attributes(dynamic_text_params))
			render
		else
			render partial: 'form_modal_dialog'
		end
	end

	def destroy
		@dynamic_text.destroy!
		render locals: {items_count: Templates::AaeProjectDynamicText.where(text_type: @dynamic_text.text_type.value, client_id: @dynamic_text.client.try(:id), video_marketing_campaign_form_id: @dynamic_text.video_marketing_campaign_form.try(:id)).size}
	end

	def add_value

	end

	def quick_edit
		limit = 50
		@clients = Client.order(:name)
		where = {}
		where[:client_id] = params[:client_id] unless params[:client_id].blank?
    where[:video_marketing_campaign_form_id] = params[:video_marketing_campaign_form_id] unless params[:video_marketing_campaign_form_id].blank?
		where[:project_type] = params[:project_type] unless params[:project_type].blank?
		@dynamic_texts = Templates::AaeProjectDynamicText.where(where).order(:client_id).order(:product_id).order(:video_marketing_campaign_form_id).page(params[:page]).per(limit)
	end

  def report
    @client_aae_template_types = %w(introduction call_to_action ending transition general bridge_to_subject collage subscription)
    @project_text_types = Templates::AaeProjectText::TEXT_GROUPES.keys
    params[:client_id] = Client.order("is_active DESC NULLS LAST, name ASC").first.id unless params[:client_id].present?
    @client = Client.find(params[:client_id])
    @clients = Client.where(is_active: true).order(:name)
    @dynamic_texts_report = {}
    Templates::AaeProjectDynamicText.unscoped.where("client_id = ?", params[:client_id].to_i).group('1,2').order('1,2').pluck('project_type, text_type, count(*)').each { |e| @dynamic_texts_report[e[0]] = {} unless @dynamic_texts_report[e[0]].present?; @dynamic_texts_report[e[0]][e[1]] = e[2] }
    @source_videos_report = {}
    SourceVideo.joins("LEFT OUTER JOIN templates_aae_project_dynamic_texts AS tapdts ON tapdts.subject_video_id = source_videos.id LEFT OUTER JOIN products ON products.id = source_videos.product_id LEFT OUTER JOIN clients ON clients.id = products.client_id").where("clients.id = ?", params[:client_id]).group('1,2,3').order('1,2,3').pluck('source_videos.id, tapdts.project_type, tapdts.text_type, count(*)').each { |e| @source_videos_report[e[0]] = {} unless @source_videos_report[e[0]].present?; @source_videos_report[e[0]][e[1]] = {} unless @source_videos_report[e[0]][e[1]].present?; @source_videos_report[e[0]][e[1]][e[2]] = e[3] }
  end

	private
		def dynamic_text_params
			params.require(:templates_aae_project_dynamic_text).permit(:id, :client_id, :video_marketing_campaign_form_id, :project_type, :text_type, :value, :product_id)
		end

		def set_dynamic_text
			@dynamic_text = Templates::AaeProjectDynamicText.find(params[:id])
		end
end
