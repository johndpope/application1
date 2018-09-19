class Templates::ImageTemplate < ActiveRecord::Base
  include Templates::ImageTemplates::Svg

  TEMPLATES_IMAGES_TMP_FOLDER = File.join('/tmp', 'broadcaster','templates', 'images')
	TEMPLATES_IMAGES_STAGE_FILE_PREFIX = "templates-images-stage-file"
  TYPES = %w(Templates::YoutubeVideoThumbnailTemplate Templates::YoutubeChannelArtTemplate Templates::GooglePlusArtTemplate Templates::ArtifactsImageTemplate Templates::StockImageTemplate)

	CATEGORIES = {people:1, jobs_and_projects:2, buildings:3, vehicles:4, billboards_and_signs:5}

  has_many :images, class_name: "Templates::ImageTemplateImage", foreign_key: "image_template_id", dependent: :destroy
  has_many :texts, class_name: "Templates::ImageTemplateText", foreign_key: "image_template_id", dependent: :destroy
  accepts_nested_attributes_for :images, allow_destroy: true
  accepts_nested_attributes_for :texts, allow_destroy: true

  belongs_to :clients, class_name: "Client", foreign_key: "client_id"
  belongs_to :products, class_name: "Product", foreign_key: "product_id"

  validates :name, presence: {message: "name is blank"}
  validates :name, uniqueness: { case_sensitive: false, message: "this name already exist" }

  validates :type, presence: {message: "type is blank"}

  has_attached_file :sample, styles: { thumb: '640x480>'}, default_url: "/system/templates/image_templates/samples/missing.png"
  validates_attachment :sample,
    content_type: {content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"]},
    allow_blank: true

  has_attached_file :svg, default_url: "/system/templates/image_templates/samples/missing.png"
  validates_attachment :svg,
    content_type: {content_type: ["image/svg+xml"]}, allow_blank: true

	extend Enumerize
  enumerize :category, in: CATEGORIES, scope: true

  attr_accessor :tmp_stage_file_name
	attr_accessor :tmp_stage_file_ext

  before_post_process :save_staged_file
  after_save :replace_original_file

  private
    def save_staged_file
  		if (path = svg.staged_path)
  			if "image/svg+xml" == svg.content_type
  				FileUtils.mkdir_p TEMPLATES_IMAGES_TMP_FOLDER
  				@tmp_stage_file_name = "#{TEMPLATES_IMAGES_STAGE_FILE_PREFIX}-#{SecureRandom.uuid}"
  				@tmp_stage_file_ext = File.extname(path)
  				FileUtils.cp(path, File.join(TEMPLATES_IMAGES_TMP_FOLDER, "#{tmp_stage_file_name}#{tmp_stage_file_ext}"))
  			end
  		end
  	end

    def replace_original_file
  		if !svg.blank? && !tmp_stage_file_name.blank?
  			path = File.join(TEMPLATES_IMAGES_TMP_FOLDER, "#{tmp_stage_file_name}#{tmp_stage_file_ext}")
  			if File.exist? path
  				FileUtils.cp path, svg.path
  				FileUtils.rm path, force: true
  			end
  		end
  		@tmp_stage_file_name = nil
  		@tmp_stage_file_ext = nil
  	end
end
