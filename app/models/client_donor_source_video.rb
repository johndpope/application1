class ClientDonorSourceVideo < ActiveRecord::Base
	belongs_to :client
	belongs_to :source_video, class_name: 'SourceVideo', foreign_key: 'source_video_id'
	has_one :product, through: :source_video

	belongs_to :recipient_source_video, class_name: 'SourceVideo', foreign_key: 'recipient_source_video_id', dependent: :destroy
	has_one :recipient_product, through: :recipient_source_video, source: :product
	has_one :recipient_client, class_name: 'Client', foreign_key: 'client_id', through: :recipient_product, source: :client

	after_create :create_recipient_source_video

	private
		def create_recipient_source_video
			ActiveRecord::Base.transaction do
				scope = Product.joins(:client).where(client_id: client.id)
				product = scope.where(parent_id: source_video.product.id).first || scope.first
				recipient_source_video = SourceVideo.create! custom_title: "#{source_video.custom_title} (#{client.name})", product_id: product.id
				self.update_attributes! recipient_source_video_id: recipient_source_video.id
			end
		end
end
