class Sandbox::Video < ActiveRecord::Base
	include Reversible

	serialize :media_info, Mediainfo

	belongs_to :video_set, class_name: "Sandbox::VideoSet", foreign_key: "sandbox_video_set_id"
	has_one :client, through: :video_set
	has_one :sandbox_client, through: :video_set
	belongs_to :source_video, class_name: "SourceVideo", foreign_key: "source_video_id"
	belongs_to :aae_project, class_name: "Templates::AaeProject", foreign_key: "templates_aae_project_id"
	belongs_to :dynamic_aae_project, class_name: "Templates::DynamicAaeProject", foreign_key: "templates_dynamic_aae_project_id", dependent: :destroy
	belongs_to :location, polymorphic: true

	VIDEO_TYPES = Templates::VIDEO_CHUNK_TYPES.merge(Templates::TRANSITION_TYPES).merge(Templates::GENERAL_TYPES)

	extend Enumerize
	enumerize :video_type, in: VIDEO_TYPES, scope: true

	validates_presence_of :sandbox_video_set_id, message: "Sandbox Video Set cannot be blank"
	validates_presence_of :video_type, message: "Video Type cannot be blank"
  validates :notes, presence: true, if: :unapproved?

	content_types = {"thumb" => ["image/jpg", "image/jpeg", "image/png", "image/gif"], "video" => ["video/mp4"]}
	size_limits = {"thumb" => {greater_than: 0.bytes, less_than: 2.megabytes}, "video" => {greater_than: 0.bytes, less_than: 200.megabytes}}
	styles = {"thumb" => {w60:"60x45", w240: "240x180", w480: "480x360"}, "video" => {}}
	%w(thumb video).each do |media_field|
		has_attached_file media_field, styles: styles[media_field], preserve_files: true
		validates_attachment_content_type media_field, allow_blank: true,
			content_type: content_types[media_field], size: size_limits[media_field]
	end

	before_save :before_save

  def unapproved?
    is_approved == false
  end

	def locality_name
		parts = []
		parts << locality.try(:name)
		parts << locality.try(:primary_region).try(:name)
		parts.reject(&:blank?).join(', ')
	end

	def self.build_from_options(options)
		video = Sandbox::Video.new
		video.source_video_id = options[:source_video]
		if !options[:location_id].blank? && !options[:location_type].blank?
			video.location_id = options[:location_id]
			video.location_type = "Geobase::#{options[:location_type].to_s.titleize}"
		end
		video.templates_aae_project_id = options[:project]
		video.templates_dynamic_aae_project_id = options[:dynamic_project]
		video.video_type = options[:type]
		video.is_active = true
		video
	end

	protected
		def before_save
			if (path = video.staged_path)
				f = open(self.video.queued_for_write[:original].path)
				media_info = Mediainfo.new f
				f.close
	      self.media_info = media_info
        self.duration = %x(ffprobe "#{path}" -show_format -v quiet | sed -n 's/duration=//p').to_f
				self.title = File.basename(path, ".*").humanize if title.blank?
      else
        unless video.path
          self.duration = nil
					self.media_info = nil
        end
      end
      true
    end
end
