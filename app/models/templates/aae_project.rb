class Templates::AaeProject < ActiveRecord::Base
  include Reversible
  has_many :aae_project_texts, dependent: :destroy
  has_many :aae_project_images, dependent: :destroy
  accepts_nested_attributes_for :aae_project_images, allow_destroy: true
  accepts_nested_attributes_for :aae_project_texts, allow_destroy: true
  belongs_to :client

  TRANSITION_TYPE = {
      simple_transition: 8,
      text_transition: 9,
      image_text_transition: 10,
			logo_transition: 16
  }

  VIDEO_TYPE = {
      introduction: 1,
      bridge_to_subject: 3,
      summary_points: 4,
      collage: 2,
      call_to_action: 5,
			phone_call_to_action: 15,
      ending: 6,
      likes_and_views: 11,
      social_networks: 12,
      credits: 7,
			subscription: 14
  }

  TYPES = VIDEO_TYPE.merge(TRANSITION_TYPE)
  TYPES_ROOT_DIRS = {simple_transition: 'Transitions/Simple Transition',
    text_transition: 'Transitions/Text Transition',
    image_text_transition: 'Transitions/Image Text Transition',
		logo_transition: 'Transitions/Logo Transition',
    introduction: 'Introduction',
    collage: 'Collage',
    bridge_to_subject: 'Bridge to subject',
    summary_points: 'Summary Points',
    call_to_action: 'Call to action',
		phone_call_to_action: 'Phone Call to Action',
    ending: 'Ending',
    likes_and_views: 'Likes & Views',
    social_networks: 'Social Networks',
    credits: 'Credits',
		subscription: 'Subscription'}

  extend Enumerize
  enumerize :project_type, in: TYPES, scope: true

  validates_presence_of :title
	validates_presence_of :name
  validates_presence_of :project_type

  has_attached_file :thumbnail, styles: { thumb: '640x480>' }
  validates_attachment_content_type :thumbnail, allow_blank: true,
    content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"],
    size: {greater_than: 0.bytes, less_than: 2.megabytes}

  has_attached_file :video, dependent: :destroy
  validates_attachment_content_type :video, allow_blank: true,
    content_type: ["video/mp4"],
    size: {greater_than: 0.bytes, less_than: 200.megabytes}

  has_attached_file :xml
  validates_attachment_content_type :xml, allow_blank: true,
    content_type: ["application/xml", "application/octet-stream"]

  default_scope{order(id: :desc)}

  before_save :set_duration

	before_save :on_before_save

  def project_dir
    File.join(Rails.configuration.aae_project_generator[:root].to_s, TYPES_ROOT_DIRS[self.project_type.to_sym].to_s, self.sub_dir.to_s, self.name.to_s)
  end

  def project_dir?
    Dir.exists? project_dir
  end

  def aepx_file_path
    File.join(project_dir, "xml.aepx")
  end

  def aepx_file_path?
    File.exists? aepx_file_path
  end

  def dynamic_texts
    aae_project_texts.where("is_static IS NOT TRUE").where('text_type IS NOT NULL').order(:name)
  end

  def static_texts
    aae_project_texts.where("is_static IS TRUE").order(:name)
  end

	%w(location_images subject_images).each do |i|
		define_method i do
			aae_project_images.try(:with_image_type, i.singularize)
		end
	end

	def logo_images
		aae_project_images.try(:with_image_type, 'client_logo', 'client_secondary_logo')
	end

	%w(logo_images location_images subject_images client_images).each do |i|
		define_method "#{i}?" do
      send(i).count > 0
    end
	end

	def client_images
		aae_project_images.where('image_type IS NULL OR image_type = ?', [Templates::AaeProjectImage::IMAGE_TYPES[:client_image]])
	end

  def dynamic_windows_base_project_path
    Rails.configuration.aae_project_generator[:target_window_base_path]
  end

  def project_texts_presented?
		return false if xml.path.blank? || !File.exist?(xml.path)

		texts_flags = []
		xml_file = open(xml.path)
    master_aepx = Nokogiri::XML(xml_file)
    xml_file.close

    puts "PROJECT ID: #{id}"

    aae_project_texts.each do |pt|
      text_flags = {id: pt.id, name: false, value: false}
      if layers = master_aepx.css("Layr string:contains('#{pt.name}')")
        text_flags[:name] = true
        layers.to_a.each do |layer|
          if btdk = layer.try(:parent).try(:at, 'btdk')
            if btdk['bdata'].include? Templates::AaeProjectText.encode_string(pt.value)
              text_flags[:value] = true
            end
          end
        end
      end
      texts_flags << text_flags
      puts "#{pt.name}"
      puts "text name is#{text_flags[:name] == false ? ' not' : ''} presented"
      puts "text value is#{text_flags[:value] == false ? ' not' : ''} presented"
    end

    [texts_flags.map{|f|f[:name]}.all?, texts_flags.map{|f|f[:value]}.all?].all?
  end

  def has_texts?
    aae_project_texts.count > 0
  end

  def has_images?
    aae_project_images.count > 0
  end

  def has_wrong_images?
    aae_project_images.where(presents_in_project: false).count > 0
  end

  def has_wrong_texts?
    aae_project_texts.where(presents_in_project: false).count > 0
  end

  def get_video_duration(video_path = self.video.path)
    return %x(ffprobe "#{video_path}" -show_format -v quiet | sed -n 's/duration=//p').to_f  unless self.video.blank?
  end

  def self.dynamic_screenshot(aae_project_id, video_file)
		aae_project = Templates::AaeProject.find(aae_project_id)
    tmp_screenshot_dir = File.join('/tmp/broadcaster', 'aae_templates', 'screenshots')
		screenshot_file = File.join tmp_screenshot_dir, "#{SecureRandom.uuid}.jpg"
		FileUtils.mkdir_p tmp_screenshot_dir
		begin
			%x(ffmpeg -i "#{video_file}" -ss "#{aae_project.screenshot_time.blank? ? '00:00:00' : aae_project.screenshot_time}" -vframes 1 "#{screenshot_file}")
			Magick::Image.read(screenshot_file).first
		ensure
			FileUtils.rm_rf screenshot_file
		end
	end

  protected
		def on_before_save
			ActiveRecord::Base.transaction do
				if(path = xml.staged_path)
					#remove existing delayed jobs
					Delayed::Job.
						where("(queue = ? OR queue = ?) AND handler like ?",
							DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_TEXTS,
							DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_IMAGES,
							"%aae_project_id: '#{self.id}'%").each do |dj|
								dj.delete
					end

					#delayed job for texts validation
					Delayed::Job.enqueue Templates::AaeProjects::ValidateTextLayersJob.new(self.id.to_s),
						queue: DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_TEXTS
					#delayed jobs for images validation
					Delayed::Job.enqueue Templates::AaeProjects::ValidateImagesJob.new(self.id.to_s),
						queue: DelayedJobQueue::TEMPLATES_AAE_PROJECT_VALIDATE_IMAGES

					self.content_lock = true
				end
			end
		end

    def set_duration
      if (path = video.staged_path)
        self.video_duration = get_video_duration(path)
      else
        unless video.path
          self.video_duration = nil
        end
      end
      true
    end
end
