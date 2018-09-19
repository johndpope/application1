class Artifacts::DynamicImage < ActiveRecord::Base
	belongs_to :image, class_name: "Artifcats::Image", foreign_key: "artifacts_image_id"
	has_many :images, class_name: "Artifacts::DynamicImageImage", foreign_key: "artifacts_dynamic_image_id", dependent: :destroy
	has_many :texts, class_name: "Artifacts::DynamicImageText", foreign_key: "dynamic_image_id", dependent: :destroy
	belongs_to :clients, class_name: "Client", foreign_key: "client_id"
	belongs_to :image_template, foreign_key: "templates_image_template_id", class_name: "Templates::ImageTemplate"
	has_attached_file :file, styles: { small: '320x240>'}
	validates_attachment_content_type :file, :content_type=>['image/jpeg', 'image/png', 'image/gif', 'image/jpg']

	def self.create_from_params(options = {})
		dynamic_image = Artifacts::DynamicImage.create!

		dynamic_image.title = options[:title]
		dynamic_image.tags = options[:tags]
		dynamic_image.client_id = options[:client_id]
		dynamic_image.templates_image_template_id = options[:image_template_id]

		if !options[:city].blank?
			dynamic_image.location_type = "Geobase::Locality"
			dynamic_image.location_id = options[:city]
		elsif !options[:region2].blank?
			dynamic_image.location_type = "Geobase::Region"
			dynamic_image.location_id  = options[:region2]
		elsif !options[:region1].blank?
			dynamic_image.location_type = "Geobase::Region"
			dynamic_image.location_id  = options[:region1]
		end

		options[:texts].each do |t|
			Artifacts::DynamicImageText.new(value: t[1], dynamic_image_id: dynamic_image.id, image_template_text_id: options[:image_template].to_s.last.to_i).save!
		end

		options[:image_type].each do |img|
			art_id	=	if img[0] == 'artifacts_logo'
									nil
								else
									img[1]
								end
			Artifacts::DynamicImageImage.new(artifacts_image_id: art_id, artifacts_dynamic_image_id: dynamic_image.id).save!
		end
		dynamic_image
	end

	def location
		self.location_type.constantize.find(self.location_id) if !(self.location_type.blank? && self.location_id.blank?)
	end

end
