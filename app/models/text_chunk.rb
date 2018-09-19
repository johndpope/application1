class TextChunk < ActiveRecord::Base
	include Reversible

	belongs_to :resource, polymorphic: true
	belongs_to :admin_user
	belongs_to :updated_by, class_name: 'AdminUser'

	validates :value, :chunk_type, presence: true

	class << self
		def chunk_types
			TextChunk.select('chunk_type').order('chunk_type').distinct.pluck('chunk_type')
		end

		def by_id(id)
			return all unless id.present?
			where('text_chunks.id = ?', id.strip)
		end

		def by_chunk_type(chunk_type)
			return all unless chunk_type.present?
			where('lower(text_chunks.chunk_type) like ?', "%#{chunk_type.downcase}%")
		end

		def by_value(value)
			return all unless value.present?
			where('lower(text_chunks.value) like ?', "%#{value.downcase}%")
		end

		def by_admin_user_id(admin_user_id)
			return all unless admin_user_id.present?
			where('text_chunks.admin_user_id = ?', admin_user_id.strip)
		end

		def by_updated_by_id(updated_by_id)
			return all unless updated_by_id.present?
			where('text_chunks.updated_by_id = ?', updated_by_id.strip)
		end

		def chunk_types_list
			TextChunk.select(:chunk_type).distinct.where('chunk_type IS NOT NULL').order(:chunk_type).pluck(:chunk_type)
		end
	end
end
