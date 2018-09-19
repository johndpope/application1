class TrainingInfo < ActiveRecord::Base
	belongs_to :admin_user

	attr_accessor :video, :document
	validates :name, :version, :group_name, :presence => true

	# file
	has_attached_file :video, :path => ':rails_root/public/system/training_infos/:id/:style/:basename.:extension', :url => '/system/training_infos/:id/:style/:basename.:extension'
	has_attached_file :document, :path => ':rails_root/public/system/training_infos/:id/:style/:basename.:extension', :url => '/system/training_infos/:id/:style/:basename.:extension'
	validates_attachment :video, :content_type => { :content_type => ['video/mp4'] }
	validates_attachment_content_type :document, content_type: [
      'application/msword',
      'application/pdf',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/zip',
			'application/vnd.ms-excel',
			'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
			'text/plain']
	validate :test

	def test
		if !self.document.present? && !self.video.present?
			errors.add(:video, "Video or Document can't be blank")
			errors.add(:document, "Video or Document can't be blank")
		elsif self.video.present? && !self.document.present?
			errors.add(:recorded_at, "Recorded at is empty") if !self.recorded_at.present?
		end
	end


	class << self
		def group_names
			group_names_sql =
			"SELECT training_infos.group_name as group_name, count(training_infos.id) as cnt
			FROM training_infos
			GROUP BY training_infos.group_name
			ORDER BY training_infos.group_name ASC"
			ActiveRecord::Base.connection.execute(group_names_sql)
		end

		def by_group_name(group_name)
			return all unless group_name.present?
			where('lower(training_infos.group_name) = ?', group_name.downcase)
		end
	end
end
