class ProductCategory < ActiveRecord::Base
	validates_presence_of :name
	validates_uniqueness_of :name, case_sensitive: false
	belongs_to :parent, class_name: 'ProductCategory'
	has_many :children, class_name: 'ProductCategory', foreign_key: 'parent_id', dependent: :nullify
end
