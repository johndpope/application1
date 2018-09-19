class Model < ActiveRecord::Base
	belongs_to :make
	belongs_to :product_category
	validates_presence_of :name
	validates_presence_of :make_id
	validates_presence_of :product_category_id
	validates_uniqueness_of :name, case_sensitive: false
end
