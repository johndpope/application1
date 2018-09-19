class VideoPart < ActiveRecord::Base
	belongs_to :video_part_item, polymorphic: true

	#video file
	has_attached_file :video, 
		:path => ":rails_root/public/system/video_parts/:id/:style/:basename.:extension",
		:url => "/video_parts/:id"
	validates_format_of :video_content_type, :with => %r{(video/mp4)}i, :on => :create
	validates_attachment :video, :presence => true,
		:content_type=>{:content_type=>['video/mp4']},  #see http://www.encoding.com/help/article/correct_mime_types_for_serving_video_files for video mime types
		:size=>{:greater_than=>0.bytes, :less_than=>200.megabytes}    
	
	def display_name
		"#{video_file_name}"
	end
end
