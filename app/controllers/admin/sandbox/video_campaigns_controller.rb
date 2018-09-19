class Admin::Sandbox::VideoCampaignsController < Admin::BaseController
	include GenericCrudOperations

	before_action :set_sandbox_clients, only: [:new, :edit]
	before_action :set_sandbox_client_and_source_video_jsons, only: [:new, :edit]

	def initialize
		super
    init_settings({
			clazz: ::Sandbox::VideoCampaign,
		  view_folder: "admin/sandbox/video_campaigns",
			item_params: [:id, :title, :sandbox_client_id, :source_video_id, :is_active, :order_nr, :source_video_id],
			index_table_header: I18n.t('admin.sandbox.video_campaigns_list'),
			index_page_header: I18n.t('admin.sandbox.video_campaigns'),
			index_json_conversion_options: {only: [:id, :title]}
		})
  end

	def sandbox_clients
		sandbox_clients = Sandbox::Client.joins(:client).select('sandbox_clients.*, clients.name as client_name').order("clients.name")
		respond_to do | format |
			format.json do
				render json: {
					total: sandbox_clients.count,
					items: sandbox_clients.page(params[:page]).per(params[:per_page])
				}
			end
		end
	end

	def source_videos
		#refactor using Ransack
		sandbox_client = Sandbox::Client.where(id: params[:sandbox_client_id]).first
		query = SourceVideo.joins(:product).joins(:client)
		query = query.where("clients.id = ?", sandbox_client.client_id) unless sandbox_client.blank?
		source_videos = query.order(:custom_title)

		respond_to do | format |
			format.json do
				render json: {
					total: source_videos.count,
					items: source_videos.page(params[:page]).per(params[:per_page])
				}
			end
		end
	end

	protected
		def set_sandbox_clients
			@sandbox_clients = Sandbox::Client.joins(:client).select('sandbox_clients.*, clients.name as client_name').order("clients.name")
		end

		def set_sandbox_client_and_source_video_jsons
			@sandbox_client_json = if defined?(@item) && !@item.sandbox_client.blank?
				@item.sandbox_client.to_json(only: [:id], include: {client: {only: [:name]}})
			else
				{}
			end

			@source_video_json = if defined?(@item) && !@item.source_video.blank?
				@item.source_video.to_json(only: [:id, :custom_title])
			else
				{}
			end
		end
end
