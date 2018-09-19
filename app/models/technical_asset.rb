class TechnicalAsset < ActiveRecord::Base
	belongs_to :parent, class_name: 'TechnicalAsset'
	
	has_many :technical_asset_tags
	has_many :technical_tags, through: :technical_asset_tags
	has_many :technical_settings
end
