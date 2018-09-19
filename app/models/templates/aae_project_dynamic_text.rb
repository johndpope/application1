class Templates::AaeProjectDynamicText < ActiveRecord::Base
	include Reversible
	belongs_to :client, foreign_key: "client_id", class_name: "Client"
	belongs_to :product, foreign_key: "product_id", class_name: "Product"
  belongs_to :video_marketing_campaign_form, foreign_key: "video_marketing_campaign_form_id", class_name: "VideoMarketingCampaignForm"
	validates_presence_of :value
	validates_presence_of :text_type

	extend Enumerize
	enumerize :project_type, in: Templates::AaeProjectText::PROJECT_TYPES, scope: true
	enumerize :text_type, in: Templates::AaeProjectText::TEXT_TYPES, scope: true

	default_scope{order(project_type: :asc, text_type: :asc,  id: :desc)}

  before_save :set_project_type

  def set_project_type
    if text_type.present?
      key = Templates::AaeProjectText::TEXT_GROUPES.select {|k,v| v.include?(text_type.to_sym) }.keys.first
      self.project_type = Templates::AaeProjectText::PROJECT_TYPES[key] unless key.nil?
    end
  end

  def text_type_limit
    set_project_type
    text_type.present? && project_type.present? ? Templates::AaeProjectText::TEXT_GROUPES_LIMITS[project_type.to_sym][text_type.to_sym] : 10000
  end

	class << self
		def generic(text_type)
			with_text_type(text_type).
			where(client_id: nil, product_id: nil, source_video_id: nil, video_marketing_campaign_form_id: nil)
		end
	end
end
