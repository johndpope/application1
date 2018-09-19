class Revision < ActiveRecord::Base

  has_many :versions, class_name: PaperTrail::Version

  before_save do
    self.name ||= versions.map { |v| "#{v.item_type}:#{v.item_id} - #{v.event.upcase}" }.join(' | ')
  end

  def revert
    Reversible.within_revision("Revert revision #{self.id}") do
      versions.order(created_at: :desc).each { |v| v.reify.save(validate: false) }
    end
  end
end
