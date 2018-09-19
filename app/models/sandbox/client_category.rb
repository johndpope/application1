class Sandbox::ClientCategory < ActiveRecord::Base
	include Reversible
	
	validates_presence_of :name, message: "Field Name cannot be empty"
	validates_uniqueness_of :name, case_sensitive: false, message: "Filed Name must be unique"
end
