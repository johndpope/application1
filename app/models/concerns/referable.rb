module Referable
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def has_references_for(group)
      has_many :"#{group}_references", -> { where(group: group) },
        class_name: 'Reference', as: :referer,
        after_add: ->(o, r) { r.group = group }
    end
  end
end
