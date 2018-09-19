class Wording < ActiveRecord::Base
	include Reversible

	belongs_to :resource, polymorphic: true
	belongs_to :admin_user
	belongs_to :updated_by, class_name: 'AdminUser'

	serialize :spins, Array

	validates :url, url: { allow_blank: true }, unless: "['Client', 'Product', 'YoutubeSetup', 'SourceVideo', 'VideoMarketingCampaignForm'].include?(resource_type)"
	validates :resource_id, presence: true, unless: "['Client', 'Product', 'YoutubeSetup', 'SourceVideo', 'VideoMarketingCampaignForm'].include?(resource_type)"
	validates :resource_type, presence: true
	validates :source, presence: true
	validates :name, presence: true

  SHORT_DESCRIPTION_WARNING = 5
  LONG_DESCRIPTION_WARNING = 10
  TRIPADVISOR_JSON_PATH = "/out/crawler/tripadvisor/<locality_id>.json"

	def spintax
		value = read_attribute(:spintax)
		value.extend SpintaxParser if value.present?
		value
	end

	def generate_spintax(protected_words = "")
		if self.spintax.blank? && self.source.present?
			spintax_result = WordAI.regular(s: self.source, quality: 'Readable', protected: protected_words)
			self.spintax = spintax_result
			self.spun_at = Time.now
			self.save
		end
	end

	def normalized_url
		@url = self.url
		if @url.blank?
			''
		else
			@url = @url unless @url[/\Ahttp:\/\//] || @url[/\Ahttps:\/\//]
			@url.gsub!(' ', '%20')
			URI.parse(@url).to_s
		end
	end

	class << self
		def by_id(id)
			return all unless id.present?
			where('wordings.id = ?', id.strip)
		end

		def by_source(source)
			return all unless source.present?
			where('lower(wordings.source) like ?', "%#{source.downcase}%")
		end

		def by_name(name)
			return all unless name.present?
			where('wordings.name = ?', name.strip)
		end

		def by_url(url)
			return all unless url.present?
			where('lower(wordings.url) like ?', "%#{url.downcase}%")
		end

		def by_admin_user_id(admin_user_id)
			return all unless admin_user_id.present?
			where('wordings.admin_user_id = ?', admin_user_id.strip)
		end

		def by_updated_by_id(updated_by_id)
			return all unless updated_by_id.present?
			where('wordings.updated_by_id = ?', updated_by_id.strip)
		end

		def by_resource_id(resource_id)
			return all unless resource_id.present?
			where('wordings.resource_id = ?', resource_id.strip)
		end

		def by_resource_type(resource_type)
			return all unless resource_type.present?
			where('wordings.resource_type = ?', resource_type.strip)
		end

		def names_list
			Wording.select(:name).distinct.where('name IS NOT NULL').order(:name).pluck(:name)
		end
	end
end
