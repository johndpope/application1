class Reference < ActiveRecord::Base
  belongs_to :referer, polymorphic: true

  validates :url, presence: true
end
