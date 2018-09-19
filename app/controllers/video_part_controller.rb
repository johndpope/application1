class VideoPartController < ApplicationController
	VIDEO_PART_LIMIT = 25

	def create_transition
	 	video_part = VideoPart.new(video_part_params)	 	
	 	if video_part.save
	 		transition = Transition.create
	 		video_part.video_part_item_id = transition.id
	 		video_part.save	 		
	 	end
	 	
		redirect_to transitions_path
	end

	def create_sales_pitch
	 	video_part = VideoPart.new(video_part_params)	 	
	 	if video_part.save
	 		sales_pitch = SalesPitch.create
	 		video_part.video_part_item_id = sales_pitch.id
	 		video_part.save	 		
	 	end
	 	
		redirect_to sales_pitches_path
	end

	def transitions		
		@video_parts = VideoPart.where(video_part_item_type: 'Transition').order(created_at: :desc).page(params[:params]).per(VIDEO_PART_LIMIT)
	end

	def destroy
		@video_part = VideoPart.find(params[:id])
		video_part_type = @video_part.video_part_item_type
		@video_part.destroy
		redirect_to eval("#{video_part_type.underscore.pluralize}_path")
	end

	def sales_pitches		
		@video_parts = VideoPart.where(video_part_item_type: 'SalesPitch').order(created_at: :desc).page(params[:params]).per(VIDEO_PART_LIMIT)
	end

	private

	def video_part_params
	    params.require(:video_part).permit(:name, :video_part_item_type, :video)
  	end
end
