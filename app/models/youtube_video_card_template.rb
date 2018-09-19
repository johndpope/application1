class YoutubeVideoCardTemplate < YoutubeVideoCard
	belongs_to :youtube_setup
	validates :card_type, :url, presence: true

	def at_json
		json = self.attributes
		json.delete('created_at')
		json.delete('updated_at')
		json.to_json
	end
end
