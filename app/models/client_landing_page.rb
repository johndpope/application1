require 'net/ssh'
class ClientLandingPage < ActiveRecord::Base
	include Reversible
	belongs_to :client
	belongs_to :product
	belongs_to :client_landing_page_template
  has_many :youtube_channels, through: :associated_websites
  has_many :associated_websites
  has_many :piwik_statistics, dependent: :destroy
  has_many :screenshots, as: :screenshotable, dependent: :destroy

	attr_accessor :header_background, :footer_background, :logo, :remove_logo, :ignore_domain

  has_attached_file :logo,
		path: ':rails_root/public/system/images/client_landing_page_logos/:id_partition/:style/:basename.:extension',
		url:  '/system/images/client_landing_page_logos/:id_partition/:style/:basename.:extension',
		styles: { thumb: '200x200>', original: {} }, convert_options: { all: "-quality 72" }
	validates_attachment :logo, content_type: { content_type: ['image/png', 'image/jpeg', 'image/gif', 'image/bmp'] },
		size: { greater_than: 0.bytes, less_than: 5.megabytes }
	has_attached_file :header_background,
		path: ':rails_root/public/system/images/client_landing_page_header_backgrounds/:id_partition/:style/:basename.:extension',
		url:  '/system/images/client_landing_page_header_backgrounds/:id_partition/:style/:basename.:extension',
		styles: { thumb: '200x200>', original: {} }, convert_options: { all: "-quality 72" }
	validates_attachment :header_background, presence: true, content_type: { content_type: ['image/png', 'image/jpeg', 'image/gif', 'image/bmp'] },
		size: { greater_than: 0.bytes, less_than: 10.megabytes }
  has_attached_file :footer_background,
		path: ':rails_root/public/system/images/client_landing_page_footer_backgrounds/:id_partition/:style/:basename.:extension',
		url:  '/system/images/client_landing_page_footer_backgrounds/:id_partition/:style/:basename.:extension',
		styles: { thumb: '200x200>', original: {} }, convert_options: { all: "-quality 72" }
	validates_attachment :footer_background, presence: true, content_type: { content_type: ['image/png', 'image/jpeg', 'image/gif', 'image/bmp'] },
		size: { greater_than: 0.bytes, less_than: 10.megabytes }

	validates :product_id, :domain, :header_title, :header_body, :footer_title, :footer_body, :footer_action_title, :footer_action_link, :client_landing_page_template, presence: true
  # validate :subdomain_and_domain_length
	before_save :clean_up_meta_keywords
  before_save :copy_backgrounds_urls
  validate :image_urls
  after_commit :upload_index_file

  YANDEX_PDD_PATH = 'https://pddimp.yandex.ru/api2/admin/dns/add'
  META_TITLE_LIMIT = 30

  def image_urls
    if self.logo_image_url.present? && !self.logo_image_url.include?(Rails.configuration.routes_default_url_options[:host])
      errors.add(:logo_image_url, "Image URL should be related to #{Rails.configuration.routes_default_url_options[:host]}")
    end
    if self.header_image_url.present? && !self.header_image_url.include?(Rails.configuration.routes_default_url_options[:host])
      errors.add(:header_image_url, "Image URL should be related to #{Rails.configuration.routes_default_url_options[:host]}")
    end
    if self.footer_image_url.present? && !self.footer_image_url.include?(Rails.configuration.routes_default_url_options[:host])
      errors.add(:footer_image_url, "Image URL should be related to #{Rails.configuration.routes_default_url_options[:host]}")
    end
  end

  def copy_backgrounds_urls
    if self.header_background.present? && self.header_background_updated_at_changed? && self.id.present?
      self.header_image_url = Rails.configuration.routes_default_url_options[:host] + self.header_background.url
    elsif self.header_image_url.present? && self.header_image_url_changed?
      self.header_background = self.header_image_url
    end
    if self.header_background.present? && self.id.present?
      self.header_image_url = Rails.configuration.routes_default_url_options[:host] + self.header_background.url
    end
    if self.footer_background.present? && self.footer_background_updated_at_changed? && self.id.present?
      self.footer_image_url = Rails.configuration.routes_default_url_options[:host] + self.footer_background.url
    elsif self.footer_image_url.present? && self.footer_image_url_changed?
      self.footer_background = self.footer_image_url
    end
    if self.footer_background.present? && self.id.present?
      self.footer_image_url = Rails.configuration.routes_default_url_options[:host] + self.footer_background.url
    end
  end

  # def subdomain_and_domain_length
  #   if [self.subdomain, self.domain].reject(&:blank?).map(&:strip).join('.').size > YoutubeVideoCard::CUSTOM_MESSAGE_LIMIT && self.ignore_domain != "true"
  #     errors.add(:subdomain, "'subdomain.domain' length must be not more than #{YoutubeVideoCard::CUSTOM_MESSAGE_LIMIT} characters.")
  #   end
  # end


  def associated_youtube_channels
    YoutubeChannel.joins("INNER JOIN associated_websites ON associated_websites.youtube_channel_id = youtube_channels.id INNER JOIN client_landing_pages ON client_landing_pages.id = associated_websites.client_landing_page_id").where("associated_websites.ready IS TRUE AND associated_websites.linked IS TRUE AND client_landing_pages.id = ?", self.id)
  end

	def clean_up_meta_keywords
		self.meta_keywords = self.meta_keywords.to_s.split(',').collect(&:strip).uniq.join(',')
	end

	def body_sections_json
		body_sections.present? ? JSON.parse(body_sections.gsub('=>', ':')) : {}
	end

	def park_domain_on_yandex(subdomain, domain)
    self.ignore_domain = "true"
    if subdomain.present?
  		data = {
  	    "domain" => domain,
  	    "type" => "A",
  	    "subdomain" => subdomain,
  			"ttl" => "14400",
  			"content" => CONFIG['vesta']['host']
  		}
  		uri = URI.parse(YANDEX_PDD_PATH)
  		https = Net::HTTP.new(uri.host,uri.port)
  		https.use_ssl = true
  		request = Net::HTTP::Post.new(uri.path, initheader = {'PddToken' => CONFIG['yandex']['pdd_token']})
  		request.set_form_data(data)
  		response = https.request(request)
  		if response.code.to_i == 200
  			json_response = JSON.parse(response.body)
  			if json_response["success"] == "ok"
  				self.parked = true
  				self.save(:validate => false)
  				true
  			else
  				ActiveRecord::Base.logger.error "Response #{response.code} #{response.message}: #{response.body}"
  				false
  			end
  		else
  			ActiveRecord::Base.logger.error "Response #{response.code} #{response.message}: #{response.body}"
  			false
  		end
    else
      self.parked = true
      self.save(:validate => false)
      true
    end
	end

	def hosting(target_url)
    self.ignore_domain = "true"
		params = {
			"user" => CONFIG['vesta']['user'],
			"password" => CONFIG['vesta']['password'],
			"cmd" => "v-add-domain",
			"arg1" => "admin",
			"arg2" => target_url
		}

		uri = URI.parse("https://#{CONFIG['vesta']['host']}:8083/api/")
		https = Net::HTTP.new(uri.host, uri.port)
		https.use_ssl = true
		https.verify_mode = OpenSSL::SSL::VERIFY_NONE
		request = Net::HTTP::Post.new(uri.request_uri)
		request.set_form_data(params)
		response = https.request(request)
		if response.code.to_i == 200 && response.body == "OK"
			self.hosted = true
			self.save(:validate => false)
			true
		else
			ActiveRecord::Base.logger.error "Response #{response.code} #{response.message}: #{response.body}"
			false
		end
	end

	def save_piwik_id(target_url)
    self.ignore_domain = "true"
		unless piwik_id.present?
			options = {
				"siteName" => target_url,
				"urls" => target_url,
			}
			response = PiwikService.get_piwik_response("API", "SitesManager.addSite", options)
			if response.code.to_i == 200
				self.piwik_id = JSON.parse(response.body)["value"].try(:to_i)
				self.save(:validate => false)
				true
			else
				ActiveRecord::Base.logger.error "Response #{response.code} #{response.message}: #{response.body}"
				false
			end
		else
			ActiveRecord::Base.logger.error "Already has piwik id"
			false
		end
	end

	def save_piwik_code
    self.ignore_domain = "true"
		unless piwik_code.present?
			options = {
				"idSite" => self.piwik_id
			}
			response = PiwikService.get_piwik_response("API", "SitesManager.getJavascriptTag", options)
			if response.code.to_i == 200
				self.piwik_code = JSON.parse(response.body)["value"]
				self.save(:validate => false)
				true
			else
				ActiveRecord::Base.logger.error "Response #{response.code} #{response.message}: #{response.body}"
				false
			end
		else
			ActiveRecord::Base.logger.error "Already has piwik code"
			false
		end
	end

	def upload_index_file
    if Rails.env.production?
      target_url = [subdomain, domain].reject(&:empty?).join(".")
      if target_url.present? && parked && hosted
    		Net::SSH.start(CONFIG['vesta']['host'], CONFIG['vesta']['user'], password: CONFIG['vesta']['password']) do |ssh|
    		  ssh.exec! "cd /home/admin/web/#{target_url}/public_html && wget -F http://broadcaster.beazil.net/clients/#{self.client_id}/client_landing_pages/#{self.id}/generate_landing_page -O index.html"
    		end
        Utils.delay(queue: DelayedJobQueue::OTHER, priority: DelayedJobPriority::HIGH).save_web_screenshot(self, self.page_url, 1600, 1600)
      end
    end
	end

	def page_url
    url = [self.subdomain, self.domain].reject(&:blank?).join('.')
    if url.present?
			url = "http://#{url}" unless url[/\Ahttp:\/\//] || url[/\Ahttps:\/\//]
			URI.parse(url).to_s
    else
			''
    end
  end

  def park_and_host
    message = nil
    subdomain = self.subdomain
    domain = self.domain
    target_url = [subdomain, domain].reject(&:empty?).join(".")
    if Rails.env.production? && target_url.present?
      message = "Domain was successfully parked, please check it within 15 minutes. Maximum time for parking domain is 24 hours. " if self.park_domain_on_yandex(subdomain, domain)
      if self.parked
        if self.save_piwik_id(target_url) || self.piwik_id.present?
          if self.save_piwik_code || self.piwik_code.present?
            if self.hosting(target_url)
              self.upload_index_file
            end
          end
        end
      end
    end
    message
  end
end
