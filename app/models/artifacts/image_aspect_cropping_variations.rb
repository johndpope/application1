class Artifacts::ImageAspectCroppingVariations < ActiveRecord::Base
	cropping_layouts = ['square', 'horizontal', 'vertical']
	gravities = ['n', 'ne', 'nw', 's', 'sw', 'se', 'e', 'w', 'c']
	styles = {}
	cropping_layouts.each do |l|
		gravities.each do |g|
			style = "#{l}_#{g}".to_sym
			styles[style] = {processors: [style]}
		end
	end

	class_eval do
		has_attached_file :file, styles: styles
	end

	validates_attachment_content_type :file,
		content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"]

	belongs_to :image, foreign_key: :image_id, class_name: 'Artifacts::Image'

	after_save :reprocess_attach

	private
		def reprocess_attach
		    if self.file.present? && Pathname.new(self.file.path).exist?
		        self.file.save
		        FileUtils.rm_rf self.file.path
						FileUtils.rm_rf File.dirname self.file.path
		    end
		end
end
