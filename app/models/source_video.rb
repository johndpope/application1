class SourceVideo < ActiveRecord::Base
  include Reversible
  include CSVAccessor
  include Referable
	include VideoResolution

  TITLE_SEPARATOR = "<sep/>"

  TYPE = {:general_video=>1, :explainer_video=>2, :case_type_video=>3}
  TARGET_AUDIENCE = {:consumers=>1, :lawyers=>2}
  CREATIVE_TYPE = {:scribbler=>1, :screen_capture=>2, :video_camera=>3}
  JURISDICTION = {:general=>1, :state_law=>2, :federal_law=>3, :international_law=>4}

  extend Enumerize
  enumerize :video_type, :in => TYPE
  enumerize :target_audience, :in => TARGET_AUDIENCE
  enumerize :creative_type, :in => CREATIVE_TYPE
  enumerize :jurisdiction, :in => JURISDICTION
	enumerize :resolution, in: VideoResolution::TYPES

  attr_accessor :video, :thumbnail
	attr_accessor :locality_id, :region1_id, :region2_id, :country_id

  belongs_to :language
  belongs_to :case_type
  belongs_to :youtube_channel
  belongs_to :broadcast_stream
  belongs_to :youtube_video_category, foreign_key: :category_id
  belongs_to :video_script
  belongs_to :product
  has_one :client, through: :product
  has_many :wordings, as: :resource
	has_one :media_info, as: :object, dependent: :destroy


	has_one :client_donor_source_video, foreign_key: 'recipient_source_video_id', class_name: 'ClientDonorSourceVideo'	#intermediate relation for donorship
	has_one :donor, class_name: 'SourceVideo', foreign_key: 'source_video_id', through: :client_donor_source_video, source: :source_video #parent donor video

  has_attached_file :thumbnail, styles: { thumb: '640x480>' }
  validates_attachment_content_type :thumbnail, allow_blank: true,
    content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"],
    size: {greater_than: 0.bytes, less_than: 2.megabytes}

  has_attached_file :video
  validates_attachment_content_type :video, allow_blank: true,
    content_type: ["video/mp4"],
    size: {greater_than: 0.bytes, less_than: 200.megabytes}

	validates_presence_of :custom_title
  validates_presence_of :product_id
  validate :video_file_custom_validations

  has_many :templates_aae_project_dynamic_texts, class_name: "Templates::AaeProjectDynamicText", foreign_key: "subject_video_id"
  accepts_nested_attributes_for :templates_aae_project_dynamic_texts, allow_destroy: true

  default_scope{order(id: :desc)}

	acts_as_taggable
	acts_as_taggable_on :artifacts_image_tags

	after_initialize do
		tag_list = tag_list.to_a.uniq{|e| e.to_s.mb_chars.downcase}.reject{|e|e.blank?}
	end

  after_create :after_create
	before_save :before_save
	before_save :set_location

  serialize :subject_title_components, Array
  has_csv_accessors_for :subject_title_components

  serialize :"wordings", Array
	has_csv_accessors_for "wordings"

  has_references_for :wordings
  accepts_nested_attributes_for :wordings, allow_destroy: true, reject_if: ->(attributes) { attributes[:source].blank? && attributes[:name].blank? }

  def video_file_custom_validations
    video_queued_for_write_original_file = self.video.queued_for_write[:original]
    if video_queued_for_write_original_file.present?
      mediainfo = Mediainfo.new video_queued_for_write_original_file.path
      self.errors[:video] << "Frames rate is not 25" if mediainfo.video.frame_rate.to_s.downcase != "25.000 fps"
      self.errors[:video] << "Resolution is not 1280 x 720" if mediainfo.video.height != 720 || mediainfo.video.width != 1280
    end
  end

  def description_wording(name)
    self.id.present? ? Wording.where("resource_id = ? AND resource_type = 'SourceVideo' AND name = ?", self.id, name).order("random()").first : nil
  end

  def destroy_description_wordings(name)
    Wording.where("resource_id = ? AND resource_type = 'SourceVideo' AND name = ?", self.id, name).destroy_all
  end

  def display_name
    "#{video_file_name}"
  end

  def jurisdiction_value
    jurisdiction.value if jurisdiction
  end

  def creative_type_value
    creative_type.value if creative_type
  end

  def video_type_value
    video_type.value if video_type
  end

  def target_audience_value
    target_audience.value if target_audience
  end

  def title_array
    titles.to_s.split(TITLE_SEPARATOR)
  end

  def get_video_duration(video_path = self.video.path)
    return %x(ffprobe "#{video_path}" -show_format -v quiet | sed -n 's/duration=//p').to_f  unless self.video.blank?
  end

	#TODO refactor
	def broadcasting_locations
		locations = []
		unless product.blank?
			product.email_accounts_setups.each do |eas|
				cities = eas.cities.reject(&:blank?)
				locations = locations + Geobase::Locality.where(id: cities) unless cities.blank?
				boroughs = eas.boroughs.reject(&:blank?)
				locations = locations + Geobase::Locality.where(id: boroughs) unless boroughs.blank?
				counties = eas.counties.reject(&:blank?)
				locations = locations + Geobase::Region.where(id: counties) unless counties.blank?
				states = eas.states.reject(&:blank?)
				locations = locations + Geobase::Region.where(id: states) unless states.blank?
			end
		end
		locations
	end

	#TODO refactor
	def broadcasting_cities
		broadcasting_locations.select{|l|l.is_a? Geobase::Locality}
	end

	def broadcasting_regions
		broadcasting_locations.select{|l|l.is_a? Geobase::Region}
	end

	def available_distribution_locations
		JSON.parse(ActiveRecord::Base.connection.
			select_value("SELECT video_workflow_source_video_available_broadcasting_locations(#{self.id})")).
			symbolize_keys
	end

	def location
		if !(location_id.nil? && location_type.nil?)
			location_type.constantize.find(location_id)
		end
	end

  protected
		def after_create
			if (path = video.staged_path)
				ActiveRecord::Base.transaction do
					mi = Mediainfo.new video.staged_path
					media_info = MediaInfo.create! object_type: 'SourceVideo', object_id: self.id, value: Hash.from_xml(mi.raw_response).to_json
				end
			end
		end

		def before_save
			unless self.new_record?
				ActiveRecord::Base.transaction do
					if (path = video.staged_path)
						self.video_duration = get_video_duration(path)
						mi = Mediainfo.new video.staged_path
						media_info = MediaInfo.where(object_type: 'SourceVideo', object_id: self.id).first_or_initialize
		        media_info.value = Hash.from_xml(mi.raw_response).to_json
						media_info.save!
		      else
						unless video.path
		        	self.video_duration = nil
							self.media_info = nil
						end
		      end
				end
			end
		end

		def set_location
			self.location_type = if !locality_id.blank?
												'Geobase::Locality'
											elsif	!region2_id.blank? || !region1_id.blank?
												'Geobase::Region'
											elsif !country_id.blank?
												'Geobase::Country'
											end
			self.location_id = if !locality_id.blank?
												locality_id
											elsif	!region2_id.blank?
												region2_id
											elsif !region1_id.blank?
												region1_id
											elsif !country_id.blank?
												country_id
											end
		end
end
