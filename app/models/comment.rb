class Comment < ActiveRecord::Base
  include Reversible
  belongs_to :resource, polymorphic: true
  validates :value, presence: true
end
