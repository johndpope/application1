class Artifacts::Image < ActiveRecord::Base
  #include Tenantable
  include Reversible
  extend Enumerize

	ARTIFACTS_TMP_FOLDER = File.join('/tmp', 'broadcaster','artifacts')
	ARTIFACTS_IMAGE_STAGE_FILE_PREFIX = "artifacts-stage-file"

  GRAVITIES = {nw: 6, ne: 7, n: 1, c: 5, s: 2, w: 3, e: 4, sw: 8, se: 9}
  FULL_GRAVITIES = {nw: :north_west, ne: :north_east, n: :north, c: :center, s: :south, w: :west, e: :east, sw: :south_west, se: :south_east}
	SPECIAL_TAGS = {
		icon_tags: {
			tags: %w(st_icon st_country_icon st_country_flag_icon st_region_icon st_region_flag_icon st_industry_icon st_call_to_action_icon),
			tag_groups: {
				general: %w(st_industry_icon st_call_to_action_icon),
				country: %w(st_country_icon st_country_flag_icon),
				region: %w(st_region_icon st_region_flag_icon),
			}
		},
		tag_mappings: {
			st_country_icon: %w(st_icon),
			st_region_icon: %w(st_icon),
			st_industry_icon: %w(st_icon),
			st_call_to_action_icon: %w(st_icon),
			st_country_flag_icon: %w(st_icon st_country_icon),
			st_region_flag_icon: %w(st_icon st_region_icon),
		}
	}
  enumerize :gravity, in: GRAVITIES, scope: true

  belongs_to :author
  belongs_to :admin_user
  has_one :image_aspect_cropping_variations, dependent: :destroy
	has_many :image_croppings, class_name: 'Artifacts::ImageCropping', foreign_key: 'artifacts_image_id', dependent: :destroy
  belongs_to :dynamic_image, class_name: "Artifacts::DynamicImage", foreign_key: "dynamic_image_id"
	belongs_to :product
  has_and_belongs_to_many :image_categories, class_name: 'Artifacts::ImageCategory', :join_table => "artifacts_images_artifacts_image_categories"

  has_attached_file :file,
		styles: { thumb: {processors: [:artifacts_image_thumb]}}, preserve_files: true
  validates_attachment_content_type :file,
    content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif", "image/svg+xml"]

  before_save :set_width_and_height

  acts_as_taggable
  acts_as_taggable_on :source_tags
	acts_as_taggable_on :special_tags

  DEFAULTS = {
    limit: 50
  }
  LIMITS = [25, 50, 100, 200]
  API_SOURCES_LIST = %w(Flickr Pixabay Pexels Unsplash Openclipart Iconfinder)
  MINIMUM_WARNING = 25
  HIGH_RESOLUTION_WIDTH_LIMIT = 720

  scope :aae_project_generator_scope, -> { where("artifacts_images.file_file_name IS NOT NULL AND artifacts_images.file_file_name <> '' AND artifacts_images.file_content_type <> 'image/svg+xml' AND artifacts_images.is_special IS NOT TRUE AND artifacts_images.is_active IS NOT FALSE AND ratio(artifacts_images.width,artifacts_images.height) >= ? AND artifacts_images.width >= ?", Templates::AaeProjectGenerator::MIN_IMG_ASPECT_RATIO, Templates::AaeProjectGenerator::MIN_IMG_WIDTH) }

  scope :stock_images_scope, ->(industry_id) { where("artifacts_images.industry_id = ?", industry_id).tagged_with("stock").tagged_with(%w(people building trucks other), any: true)}

  include Rails.application.routes.url_helpers
	include ImageLicenseInfo

  def to_jq_upload
    {
      "id" => read_attribute(:id),
      "name" => read_attribute(:file_file_name),
      "size" => read_attribute(:file_file_size),
      "url" => file.url(:thumb),
      "path" => file.path,
      "delete_url" => artifacts_image_path(self),
      "delete_type" => "DELETE"
    }
  end

  def is_local?
    is_local == true
  end

  def is_dynamic?
    !self.dynamic_image_id.blank?
  end

  def reusable?
    reusable == true
  end

  after_create do
    image_type = self.type || self.class.name
    # self.delay(queue: DelayedJobQueue::ARTIFACTS_IMAGE_ASCPECT_CROPPING_VARIATIONS, priority: 2).make_aspect_cropping_variations if file.exists?
    Delayed::Job.enqueue Artifacts::ImageAspectCroppingJob.new(image_type, self.id), queue: DelayedJobQueue::ARTIFACTS_IMAGE_ASCPECT_CROPPING_VARIATIONS, priority: DelayedJobPriority::LOW if file.exists?
  end

  after_save do
    if file.exists? && file_file_name_changed? && file_content_type != "image/svg+xml"
      system(
        "convert \"#{file.path}\" -auto-orient -set comment 'Artifacts::Image##{id}' \"#{file.path}\""
      )
    end
  end

	attr_accessor :special_tags

	attr_accessor :tmp_stage_file_name
	attr_accessor :tmp_stage_file_ext
  attr_accessor :url_o
	before_post_process :save_staged_file
	after_save :replace_original_file
	after_save :set_croppings

	def save_staged_file
		if (path = file.staged_path)
			if (%w(image/svg+xml).include? file.content_type)
				FileUtils.mkdir_p ARTIFACTS_TMP_FOLDER
				@tmp_stage_file_name = "#{ARTIFACTS_IMAGE_STAGE_FILE_PREFIX}-#{SecureRandom.uuid}"
				@tmp_stage_file_ext = File.extname(path)
				FileUtils.cp(path, File.join(ARTIFACTS_TMP_FOLDER, "#{tmp_stage_file_name}#{tmp_stage_file_ext}"))
			end
		end
	end

	def replace_original_file
		if !file.blank? && !tmp_stage_file_name.blank?
			path = File.join(ARTIFACTS_TMP_FOLDER, "#{tmp_stage_file_name}#{tmp_stage_file_ext}")
			if File.exist? path
				FileUtils.cp path, file.path
				FileUtils.rm path, force: true
			end
		end
		@tmp_stage_file_name = nil
		@tmp_stage_file_ext = nil
	end

  class << self
    def list(options = {})
      limit = options[:limit] || DEFAULTS[:limit]
      criteria = options[:ransack] || {}
      criteria[:title_or_description_or_tags_name_or_special_tags_name_or_country_or_region1_or_region2_or_city_cont] = options[:q]
      scope = order(created_at: :desc).ransack(criteria).result(distinct: true)
      scope = scope.where("file_file_name IS #{options[:import_status] == 'imported' ? 'NOT' : ''} NULL") if %w(imported importing).include? options[:import_status]
      if(%w(true false might_have).include? options[:has_gravity_point])
        scope = scope.where("gravity IS #{options[:has_gravity_point] == 'true' ? 'NOT' : ''} NULL")
        social_channel_art_images = Artifacts::Image.with_tags(['social_channel_art']).pluck(:id)
        scope = scope.where.not(id: social_channel_art_images) if options[:has_gravity_point] == "might_have"
      end
      scope = scope.where("broadcaster_property IS #{options[:broadcaster_property] == 'no' ? 'NOT' : ''} TRUE") if %w(yes no).include? options[:broadcaster_property]
      scope = scope.where("is_local IS #{options[:is_local] == 'false' ? 'NOT' : ''} TRUE") if %w(true false).include? options[:is_local]
      scope = scope.where("reusable #{options[:reusable] == 'no' ? '= FALSE' : '= TRUE OR reusable IS NULL'}") if %w(yes no).include? options[:reusable]
      scope = scope.where("file_content_type LIKE ?","%#{options[:extension]}%") if %w(jpeg png svg).include? options[:extension]
      scope = scope.where("client_id in (?)", options[:client_id].to_s.strip.split(",").map(&:to_i)) if options[:client_id].present?
      scope = scope.where("industry_id = ?", options[:industry_id]) if options[:industry_id].present?
      scope = scope.where("use_for_landing_pages IS #{options[:use_for_landing_pages] == 'no' ? 'NOT' : ''} TRUE") if %w(yes no).include? options[:use_for_landing_pages]
      options[:by_resolution] = 'high' unless options[:by_resolution].present?
      scope = scope.where("width #{options[:by_resolution] == 'high' ? '>=' : '<'} ?", Artifacts::Image::HIGH_RESOLUTION_WIDTH_LIMIT) if %w(high low).include? options[:by_resolution]

      unless options[:image].blank?
        arr = []
        Artifacts::ImagesArtifactsImageCategory.where(:image_category_id => options[:image][:categories].values).each do |item|
          arr.push(item.artifacts_images.id)
        end
        scope = scope.where(id: arr)
      end

      unless options[:rating].blank?
        if options[:rating] == "0"
          scope = scope.where("rating is null")
        else
          scope = scope.where("rating = ?", options[:rating])
        end
      end

      if !options[:lat].blank? && !options[:lng].blank?
        options[:radius] = 1 if options[:radius].blank?
        scope = scope.where("id in (SELECT get_image_ids_by_radius(#{options[:lat]},#{options[:lng]},#{options[:radius]},'#{options[:country_name]}'))")
      end
      result = {
        total: scope.count,
        items: scope.page(options[:page]).per(limit).to_a,
        scope: scope
      }
      result
    end

    def full_text_search(query)
      if query.present?
        tokens = sanitize(query).split(/\W/).map(&:downcase).uniq.select(&:present?)
        operand = '&'
        terms = -> { tokens.join(" #{operand} ") }
        filter = -> { "to_tsvector('english', base) @@ to_tsquery('#{terms.call}')" }
        rank = -> { "ts_rank(to_tsvector(base), to_tsquery('#{terms.call}'))" }
        search = -> { from('artifacts_images_view artifacts_images').where(filter.call) }
        if (fetch = search.call).any?
          fetch
        else
          operand = '|'
          search.call
        end.order("#{rank.call} DESC")
      else
        all
      end
    end

    def stock_images_by_client(client)
      if client.industry.present?
        if client.video_marketing_campaign_form.present?
          if client.video_marketing_campaign_form.use_stock_images
              deleted_stock_images = client.video_marketing_campaign_form.deleted_stock_images.to_a.reject(&:blank?).compact.map(&:to_i)
              deleted_stock_images = [-1] unless deleted_stock_images.present?
              Artifacts::Image.where("artifacts_images.id not in (?)", deleted_stock_images).aae_project_generator_scope.stock_images_scope(client.industry_id)
          else
            Artifacts::Image.where(id: nil)
          end
        else
          Artifacts::Image.aae_project_generator_scope.stock_images_scope(client.industry_id)
        end
      else
        Artifacts::Image.where(id: nil)
      end
    end

    def distribution_by_region1
      Hash[
        where.not(region1: ['', nil]).group('1,2').order('3 DESC').pluck('country,region1,count(*)').map { |e|
          ["#{e[1]}, #{e[0]}", e[2]]
        }
      ]
    end

    def distribution_by_region2
      Hash[
        where.not(region2: ['', nil]).group('1,2,3').order('4 DESC, 3')
        .pluck('country,region1,region2,count(*)').map do |e|
          ["#{e[2]}, #{e[1]}", e[3]]
        end
      ]
    end

    def distribution_by_city
      Hash[
        where.not(city: ['', nil]).group('1,2').order('3 DESC').pluck('region1,city,count(*)').map { |e|
          ["#{e[1]}, #{e[0]}", e[2]]
        }
      ]
    end

    def distribution_by_tag
      grouping = Artifacts::Image.joins(
        <<-SQL
          LEFT OUTER JOIN taggable_taggings tti
            ON artifacts_images.id = tti.taggable_id
              AND tti.taggable_type = 'Artifacts::Image'
              AND tti.context = 'tags'
        SQL
      ).joins("LEFT OUTER JOIN taggable_tags tt ON tti.tag_id = tt.id AND tt.name IS NOT NULL").
      group('1').order('2 DESC').pluck('tt.name, count(*)')
      Hash[grouping]
    end

    def distribution_by_admin_user(days_ago = (Date.today - Time.at(0).to_date).to_i)
      grouping = Artifacts::Image.joins("LEFT OUTER JOIN admin_users ON admin_users.id = artifacts_images.admin_user_id")
      .where("artifacts_images.created_at >= ?", days_ago.days.ago)
      .group('1').order('2 DESC').pluck('email, count(*)')
      Hash[grouping]
    end

    def recent_downloads(timeframe)
      where('file_file_name IS NOT NULL AND file_updated_at > ?', timeframe.ago).count
    end

    def pending_downloads
      Delayed::Job.where('handler like ?', "%Artifacts::ImageImportJob\nimage_type: #{name}%").count
    end

    def failed_downloads
      Delayed::Job.where('handler like ? AND last_error IS NOT NULL', "%Artifacts::ImageImportJob\nimage_type: #{name}%").count
    end

    def downloaded
        where("file_file_name IS NOT NULL AND file_file_name != ''")
    end

    def with_tags(tags = [])
      taggable_tags = ActsAsTaggableOn::Tag.where("LOWER(name) IN(?)", tags.map(&:downcase))
      taggable_taggings = ActsAsTaggableOn::Tagging.where(tag_id: taggable_tags, taggable_type: Artifacts::Image, context: 'tags')
      where(id: taggable_taggings.select('taggable_id'))
    end

    def with_aspect_ratio(aspect_ratio, min_width = 0)
      where('ratio(width,height) >= ? AND width >= ?', aspect_ratio, min_width)
    end

    def with_locality(geobase_locality)
      where(country: geobase_locality.try(:primary_region).try(:country).try(:name),
        region1: geobase_locality.try(:primary_region).try(:name),
        city: geobase_locality.try(:name))
    end

		def region1_images(geobase_region, limit = nil)
			state_localities = Geobase::Locality.
				where(primary_region_id: geobase_region.id).
				where.not(population: nil).
				order(population: :desc).
				limit(limit).
				pluck(:name)
			where(country: geobase_region.country.name).
			where(region1: geobase_region.name).
			where(city: state_localities)
		end

    def with_region(geobase_region, limit = nil)
      return (if geobase_region.level == 1 #state level
        				region1_images(geobase_region, limit)
      				elsif geobase_region.level == 2 #county level
								where(country: geobase_region.country.name).
								where(region1: geobase_region.parent.name).
								where(region2: geobase_region.name)
      			end)
    end

    def with_location(location, limit = nil)
			if location.is_a? Geobase::Locality
				with_locality(location)
			elsif location.is_a? Geobase::Region
				with_region(location, limit)
			end
    end
  end

  def imported?
    !file.blank?
  end

  def import
    raise ArgumentError.new('Undefined source_id') if source_id.nil?
    raise ArgumentError.new('Undefined type') if type.nil?
  end

  def exists?
    source_id && Artifacts::Image.where(source_id: source_id.to_s, type: type).any?
  end

  def make_aspect_cropping_variations
		if self.file.present?
			acv = Artifacts::ImageAspectCroppingVariations.where(image_id: self.id).first_or_initialize
			f = File.open(self.file.path)
			acv.file = f
	    acv.save!
			f.close
		end
  end

  def metadata
    @details ||= (
      if file.exists?
        details_string = %x{identify -verbose "#{file.path}"}.scrub('*')
        details_string.each_line.with_object([]).inject({}) do |details_hash, (line, key_stack)|
          level = line[/^\s*/].length / 2 - 1
          next details_hash if level == -1 # we ignore the root level
          key_stack.pop if level < key_stack.size

          key, _, value = line.partition(/:[\s\n]/).map(&:strip)
          hash = key_stack.inject(details_hash) { |hash, key| hash.fetch(key) }
          if value.empty?
            hash[key] = {}
            key_stack.push key
          else
            hash[key] = value
          end

          details_hash
        end
      else
        {}
      end
    )
  end

  def crop(size = '100x100')
		raise "Image attachment is blank" unless self.file.exists?
    gravity = self.gravity.nil? ? 'center' : Artifacts::Image::FULL_GRAVITIES[self.gravity.to_sym].to_s
    ImagemagickScripts.aspect_crop(file.path, size, gravity)
  end

  protected

    def set_width_and_height
      if (path = file.staged_path)
        geometry = Paperclip::Geometry.from_file(path)
        self.width = geometry.width.to_i
        self.height = geometry.height.to_i
      else
        unless file.path
          self.width = nil
          self.height = nil
        end
      end
      true
    end

		def set_croppings
			if self.gravity_changed?
				ActiveRecord::Base.transaction {
					Delayed::Job.where(queue: DelayedJobQueue::ARTIFACTS_GENERATE_IMAGE_CROPPINGS).
						where("handler like ?", "%image_id: #{self.id}\n%").delete_all
					Delayed::Job.enqueue Artifacts::GenerateImageCroppingsJob.new(self.id),
						queue: DelayedJobQueue::ARTIFACTS_GENERATE_IMAGE_CROPPINGS,
						priority: DelayedJobPriority::LOW
				}
			end
		end

end
