class AdminUserCompany < ActiveRecord::Base
  include Reversible
  validates :name, uniqueness: true
  has_many :admin_users
end
