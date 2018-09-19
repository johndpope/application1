class DealerCertification < ActiveRecord::Base
	belongs_to :dealer, class_name: 'Client', foreign_key: 'client_id'
	belongs_to :manufacturer, class_name: 'Client', foreign_key: 'manufacturer_id'

	validates_uniqueness_of :client_id, :scope => :manufacturer_id
end
