class Product < ActiveRecord::Base
  include Reversible
	include CSVAccessor
	include Referable
  belongs_to :client
  belongs_to :parent, class_name: 'Product', foreign_key: :parent_id
  has_and_belongs_to_many :representatives
	has_many :wordings, as: :resource
	has_many :client_landing_pages, dependent: :destroy
	has_and_belongs_to_many :contracts
	has_many :email_accounts_setups, through: :contracts
  has_many :source_videos
  validates :name, :tag_list, presence: true
	before_save :before_save
	before_save :clean_up_protected_words
  after_create :generate_landing_page

  attr_accessor :logo
	attr_accessor :remove_logo
  has_attached_file :logo,
    path: ":rails_root/public/system/images/products/:id_partition/:style/:basename.:extension",
    url:  "/system/images/products/:id_partition/:style/:basename.:extension",
    styles: {thumb:"150x150>"}
  validates_attachment :logo,
    content_type: {content_type: ['image/png']},
    size: {greater_than: 0.bytes, less_than: 2.megabytes}

	serialize :"wordings", Array
	has_csv_accessors_for "wordings"

	has_references_for :wordings
	accepts_nested_attributes_for :wordings, allow_destroy: true, reject_if: ->(attributes) { attributes[:source].blank? && attributes[:name].blank? }

	acts_as_taggable
	acts_as_taggable_on :artifacts_image_tags

  serialize :subject_title_components, Array
  has_csv_accessors_for :subject_title_components

	def description_wording(name)
		self.id.present? ? Wording.where("resource_id = ? AND resource_type = 'Product' AND name = ?", self.id, name).order("random()").first : nil
	end

  def description_wording_with_parent(name)
    if self.id.present?
      if self.parent.present?
        Wording.where("(resource_id = ? OR resource_id = ?) AND resource_type = 'Product' AND name = ?", self.id, self.parent_id, name).order("random()").first
      else
        Wording.where("resource_id = ? AND resource_type = 'Product' AND name = ?", self.id, name).order("random()").first
      end
    else
      nil
    end
  end

	def destroy_description_wordings(name)
		Wording.where("resource_id = ? AND resource_type = 'Product' AND name = ?", self.id, name).destroy_all
	end

	def clean_up_protected_words
		self.protected_words = self.protected_words.to_s.split(",").collect(&:strip).uniq.join(",")
	end

  def tag_list_with_parent
    if self.parent.present?
      (self.parent.tag_list + self.tag_list).uniq
    else
      self.tag_list
    end
  end

  private
    def generate_landing_page
      unless client.ignore_landing_pages
        begin
          backgrounds = Artifacts::Image.where("client_id = ? AND use_for_landing_pages = TRUE AND file_file_size > 0", self.client_id).order("random()").first(2)
          if self.client.industry.present? && backgrounds.size < 2
            backgrounds = backgrounds + Artifacts::Image.stock_images_by_client(self.client).where("artifacts_images.use_for_landing_pages = TRUE").order('RANDOM()').first(2 - backgrounds.size)
          end
          header_background_url = backgrounds.first.present? ? Rails.configuration.routes_default_url_options[:host] + backgrounds.first.file.url : nil
          footer_background_url = backgrounds.second.present? ? Rails.configuration.routes_default_url_options[:host] + backgrounds.second.file.url : nil
          client_landing_page = ClientLandingPage.new
          client_landing_page.header_image_url = header_background_url
          client_landing_page.footer_image_url = footer_background_url
          client_landing_page.client_landing_page_template = ClientLandingPageTemplate.order("random()").first
          client_landing_page.product = self
          client_landing_page.client = self.client
          client_landing_page.title = self.client.name
          client_landing_page.logo_image_url = Rails.configuration.routes_default_url_options[:host] + self.client.logo.url if self.client.logo.present?
          client_landing_page.client_landing_page_template_id = ClientLandingPageTemplate.all.order('random()').first.try(:id)
          client_landing_page.meta_keywords = self.tag_list_with_parent.shuffle.join(", ")
          client_landing_page.meta_description = self.description_wording_with_parent('long_description').try(:source).to_s
          client_landing_page.header_title = self.client.name
          client_landing_page.header_body = self.client.description_wording("short_description").try(:source)
          client_landing_page.footer_title = "Call #{self.client.name} #{number_to_phone(self.client.phones.first.to_s.gsub(/[^0-9]/, '').first(10), area_code: true)}"
          client_landing_page.footer_body = self.description_wording_with_parent('short_description').try(:source) || self.description_wording_with_parent('long_description').try(:source).to_s
          client_landing_page.footer_action_title = TextChunk.where(chunk_type: "client_landing_page_action").order("random()").first.try(:value)
          client_landing_page.footer_action_link = self.client.website
          client_landing_page.save(:validate => false)

          client_landing_page.domain = ClientLandingPage.where("product_id = ? AND parked = true AND hosted = true", self.parent_id || -1).first.try(:domain) || ClientLandingPage.joins(:client).where("clients.industry_id = ? AND client_landing_pages.parked = true AND client_landing_pages.hosted = true AND client_landing_pages.domain IS NOT NULL", self.client.industry_id).group(:domain).count.sort{|a,b| b.second <=> a.second}.try(:first).try(:first)
          if client_landing_page.domain.present? && Domain.where(name: client_landing_page.domain.downcase.strip).present?
            # subdomain_limit = CallToActionOverlay::DISPLAY_URL_LIMIT - client_landing_page.domain.size - 3
            # if subdomain_limit > 0
              client_landing_page.subdomain = self.client.name.downcase.gsub(/[^0-9a-z]/i, '')
              client_landing_page.subdomain = client_landing_page.subdomain + self.client.products.size.to_s if self.client.products.size > 1
              client_landing_page.save(:validate => false)
              #auto park and host
              client_landing_page.park_and_host
            # end
          end
        rescue
        end
      end
    end

		def before_save
			self.logo = nil if self.remove_logo == 'true'
		end
end
