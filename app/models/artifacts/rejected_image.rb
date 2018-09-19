class Artifacts::RejectedImage < ActiveRecord::Base
  include Reversible
  validates :source_id, :presence => true, :uniqueness => {:scope => :source_type}
end
