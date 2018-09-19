class Paragraph < ActiveRecord::Base
	include Reversible
  belongs_to :resource, polymorphic: true
  acts_as_list scope: [:resource_id, :resource_type, :scope]
end
