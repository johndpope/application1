class Templates::DynamicAaeProject < ActiveRecord::Base
	include Reversible

	belongs_to :aae_project, class_name: "Templates::AaeProject", foreign_key: "aae_project_id"
	belongs_to :product, class_name: "Product", foreign_key: "client_product_id"
	belongs_to :location, polymorphic: true
	belongs_to :source_video, class_name: "SourceVideo", foreign_key: "source_video_id"
	belongs_to :rendering_machine
	has_one :client, through: :product
	has_many :dynamic_aae_project_texts, dependent: :destroy
	has_many :dynamic_aae_project_images, dependent: :destroy

	TARGETS = {sandbox: 1, distribution: 2, test: 3}
	extend Enumerize
	enumerize :target, in: TARGETS, scope: true

	has_attached_file :rendered_video
	validates_attachment :rendered_video, allow_blank: true,
		content_type: {content_type: ['video/mp4'], message: 'Invalid content type'},
		size: {greater_than: 0.bytes, less_than: 200.megabytes, message: 'File size exceeds the limit allowed'}

	has_attached_file :rendered_video_thumb,
		styles: {w60:"60x45", w240: "240x180", w480: "480x360"}
	validates_attachment_content_type :rendered_video_thumb, allow_blank: true,
		content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"],
		size: {greater_than: 0.bytes, less_than: 20.megabytes, message: 'File size exceeds the limit allowed'}

	has_attached_file :tar_project
	validates_attachment :tar_project, allow_blank: true, content_type: {content_type: ['application/x-tar']}

	has_one :media_info, as: :object, dependent: :destroy

	after_create :after_create
	before_save :before_save

	def create_rendered_video_thumb
		if self.rendered_video.exists?
			thumb_file_path = File.join('/tmp', "#{SecureRandom.uuid}.jpg")
			begin
				Templates::AaeProject.dynamic_screenshot(self.aae_project_id, self.rendered_video.path).write(thumb_file_path)
				self.rendered_video_thumb = open(thumb_file_path)
				self.save!
			ensure
				FileUtils.rm_rf thumb_file_path
			end
		end
	end

	private
		def after_create
			if (path = rendered_video.staged_path)
				ActiveRecord::Base.transaction do
					mi = Mediainfo.new rendered_video.staged_path
					media_info = MediaInfo.create! object_type: 'Templates::DynamicAaeProject', object_id: self.id, value: Hash.from_xml(mi.raw_response).to_json
				end
			end
		end

		def before_save
			unless self.new_record?
				ActiveRecord::Base.transaction do
					if (path = rendered_video.staged_path)
						self.rendered_video_duration = %x(ffprobe "#{path}" -show_format -v quiet | sed -n 's/duration=//p').to_f
						mi = Mediainfo.new rendered_video.staged_path
						media_info = MediaInfo.where(object_type: 'Templates::DynamicAaeProject', object_id: self.id).first_or_initialize
						media_info.value = Hash.from_xml(mi.raw_response).to_json
						media_info.save!
					else
						unless rendered_video.path
							self.rendered_video_duration = nil
							self.media_info = nil
						end
					end
				end
			end
		end
end
