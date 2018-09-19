module Reversible
	def self.included(base)
		base.class_eval do
			has_paper_trail ignore: [ :created_at, :updated_at ], meta: { revision_id: :revision_id }
			after_commit :complete_revision
		end
	end

	def self.current_revision
		@@revision ||= Revision.new(id: SecureRandom.uuid)
	end

	def self.within_revision(name)
		Reversible.current_revision.name = name
		ActiveRecord::Base.transaction { yield }
		Reversible.current_revision
	end

	def revision_id
		Reversible.current_revision.try(:id)
	end

	def complete_revision
		if defined?(@@revision) && @@revision && PaperTrail::Version.where(revision_id: @@revision.id).any?
			@@revision.save
			@@revision = nil
		end
	end
end
