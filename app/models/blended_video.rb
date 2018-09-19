class BlendedVideo < ActiveRecord::Base
	include Reversible

	belongs_to :source_video, class_name: "SourceVideo", foreign_key: "source_id"
	belongs_to :location, polymorphic: true
	has_one :client, through: :source_video
	has_one :rendering_settings, through: :client
	has_many :blended_video_chunks, dependent: :destroy
	has_many :dynamic_aae_project_images, through: :blended_video_chunks
	has_many :dynamic_aae_projects, through: :blended_video_chunks,
		class_name: "Templates::DynamicAaeProject", foreign_key: "templates_dynamic_aae_project_id"
	has_one :youtube_video, class_name: 'YoutubeVideo', foreign_key: 'blended_video_id'
	has_one :blended_video_workflow_status, dependent: :destroy

	has_attached_file :file, dependent: :destroy
	validates_attachment_content_type :file, allow_blank: true, content_type: ["video/mp4"]

	after_create :create_workflow_status

	def rendering_time
		BlendedVideoChunk.
			joins(:dynamic_aae_project).
			where(blended_video_id: id).
			sum("templates_dynamic_aae_projects.rendering_time").to_i
	end

	%w(completed rejected accepted).each do |t|
		define_method "#{t}?" do
			BlendedVideo.select("blended_video_#{t}(#{self.id}) AS is_#{t}").first["is_#{t}"]
		end
	end

	def youtube_channel(channel_type = :business)
		location_type = self.location_type.to_s.gsub('Geobase::','').downcase
		YoutubeChannel.
			joins(:google_account).
			joins(:client).
			joins('INNER JOIN products on products.client_id = clients.id').
			joins('INNER JOIN source_videos on source_videos.product_id = products.id').
			joins('INNER JOIN blended_videos on blended_videos.source_id = source_videos.id').
			where("blended_videos.id = ? AND youtube_channels.channel_type = ? AND email_accounts.#{location_type}_id = ?", self.id, YoutubeChannel::CHANNEL_TYPES[channel_type], self.location_id).first
	end

	def build_workflow_status
		rendering_status = {}
		segment_map = blended_video_chunks.
			without_chunk_type(:subject).
			joins("LEFT OUTER JOIN templates_dynamic_aae_projects ON blended_video_chunks.templates_dynamic_aae_project_id = templates_dynamic_aae_projects.id").
			select("blended_video_chunks.id, templates_dynamic_aae_projects.is_rendered, blended_video_chunks.templates_dynamic_aae_project_id, templates_dynamic_aae_projects.is_created, templates_dynamic_aae_projects.is_transmitted, blended_video_chunks.accepted").
			map{|bvc|{
				bvc.id => {is_created: bvc.is_created,
					is_transmitted: bvc.is_transmitted,
					is_rendered: bvc.is_rendered,
					is_approved: bvc.accepted,
					dynamic_aae_project_id: bvc.templates_dynamic_aae_project_id}}
			}.inject(:merge)

		video_set = BlendedVideo.
			joins("LEFT OUTER JOIN youtube_videos ON youtube_videos.blended_video_id = blended_videos.id").
			where("blended_videos.id" => self.id).
			select("blended_videos.file_file_name, youtube_videos.id as youtube_video_id, youtube_videos.ready as youtube_video_ready, youtube_videos.linked as youtube_video_linked, youtube_videos.youtube_video_id as youtube_video_source_id, youtube_videos.thumbnail_file_name as youtube_video_thumbnail_file_name").
			first

		rendering_status[:some_segments_generated]						= segment_map.values.any?{|v|v[:is_created] == true}
		rendering_status[:some_segment_generation_failed]			= false
		rendering_status[:all_segments_generated]							= segment_map.values.all?{|v|v[:is_created] == true}
		rendering_status[:some_segments_transmitted]					= segment_map.values.any?{|v|v[:is_transmitted] == true}
		rendering_status[:some_segment_transmition_failed]		= false
		rendering_status[:all_segments_transmitted]						= segment_map.values.all?{|v|v[:is_transmitted] == true}
		rendering_status[:some_segments_rendered]							= segment_map.values.any?{|v|v[:is_rendered] == true}
		rendering_status[:some_segment_rendering_failed]			= false
		rendering_status[:all_segments_rendered]							= segment_map.values.all?{|v|v[:is_rendered] == true}
		rendering_status[:some_segments_rejected]							= segment_map.values.any?{|v|v[:is_approved] == false}
		rendering_status[:some_segments_approved] 						= segment_map.values.any?{|v|v[:is_approved] == true}
		rendering_status[:all_segments_approved]							= segment_map.values.all?{|v|v[:is_approved] == true}
		rendering_status[:is_blended]													= !video_set.file_file_name.nil? || !video_set.youtube_video_id.nil?
		rendering_status[:youtube_video_content_generated]		= !video_set.youtube_video_id.nil?
		rendering_status[:youtube_video_thumbnail_generated] 	= !video_set.youtube_video_thumbnail_file_name.nil?
		rendering_status[:youtube_video_posted]								= video_set.youtube_video_linked == true && video_set.youtube_video_ready == true && !video_set.youtube_video_source_id.nil?
		rendering_status
	end

	class << self
		%w(completed rejected accepted completed_unreviewed).each do |t|
			define_method t do
				BlendedVideo.where("blended_video_#{t}(id)::int = 1")
			end
		end

		def rendering_progress(id)
			ActiveRecord::Base.connection.select_value("SELECT video_workflow_get_video_set_progress(#{id})")
		end

		def rendering_progresses(ids)
			JSON.parse(ActiveRecord::Base.connection.select_value("SELECT video_workflow_get_video_set_progresses(Array[#{ids.to_a.join(',')}]::integer[])"))
		end

		def by_workflow_status_name(status_name)
			if %w(rejected rendering rendered_unreviewed).include? status_name
				send(status_name)
			else
				all
			end
		end

		def blended
			where("blended_videos.workflow_status->>'is_blended' = 'true'")
		end

		def rendering
			where("blended_videos.workflow_status->>'all_segments_rendered' = 'false'")
		end

		def rendered
			where("blended_videos.workflow_status->>'all_segments_rendered' = 'true'")
		end

		def rejected
			where("blended_videos.workflow_status->>'some_segments_rejected' = 'true'")
		end

		def rendered_unreviewed
			where("blended_videos.workflow_status->>'all_segments_rendered' = 'true'").
			where("blended_videos.workflow_status->>'all_segments_approved' = 'false'").
			where("blended_videos.workflow_status->>'some_segments_rejected' = 'false'")
		end

		def segments_transmitted
			where("blended_videos.workflow_status->>'all_segments_transmitted' = 'true'")
		end

		def segments_generated
			where("blended_videos.workflow_status->>'all_segments_generated' = 'true'")
		end
	end

	private
		def create_workflow_status
			BlendedVideoWorkflowStatus.create! blended_video_id: self.id, workflow_status: {}
		end
end
