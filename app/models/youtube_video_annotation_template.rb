class YoutubeVideoAnnotationTemplate < YoutubeVideoAnnotation
	belongs_to :youtube_setup
	validates :description, :link, presence: true

	def at_json
		json = self.attributes
		json.delete('created_at')
		json.delete('updated_at')
		json.to_json
	end
end
