class Attribution < ActiveRecord::Base
  belongs_to :resource, polymorphic: true
  belongs_to :component, polymorphic: true
end
