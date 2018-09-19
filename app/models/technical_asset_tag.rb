class TechnicalAssetTag < ActiveRecord::Base
	belongs_to :technical_asset
	belongs_to :technical_tag
end
