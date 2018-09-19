class Sandbox::VideoBlendersController < Sandbox::BaseController
	before_action :set_sandbox_client, only: [:show, :video_info, :regenerate_channel_name, :regenerate_channel_tags, :regenerate_channel_descriptions, :regenerate_channel_arts, :regenerate_channel_icon, :regenerate_video_title, :regenerate_video_descriptions, :regenerate_video_thumbnail_image, :regenerate_video_tags, :refresh_pattern, :regenerate_youtube_channel, :regenerate_youtube_video]
	before_action :init_blender_settings, only: [:show, :regenerate_channel_name, :regenerate_youtube_channel, :regenerate_youtube_video]
	before_action :set_timeline_videos, only: [:show]
	before_action :sanitize_params, only: :blend

	def show
		sandbox_youtube_channel = Sandbox::YoutubeChannel.where(:sandbox_client_id => @sandbox_client.id)
		sandbox_youtube_video = Sandbox::YoutubeVideo.where(:sandbox_client_id => @sandbox_client.id)
		youtube_setup = @sandbox_client.client.youtube_setups

		if !youtube_setup.blank?
			@tags = youtube_setup.order('random()').first.other_business_channel_tags.map{|t| t.name}.join(',')
			entity = youtube_setup.order('random()').first.business_channel_entity.sample
			subject = youtube_setup.order('random()').first.business_channel_subject.sample
		elsif !sandbox_youtube_channel.blank?
			@tags = sandbox_youtube_channel.order('random()').first.tags
			entity = sandbox_youtube_channel.order('random()').first.title_entity_components.sample
			subject = sandbox_youtube_channel.order('random()').first.title_subject_components.sample

			client_short_description = sandbox_youtube_channel.order('random()').first.client_short_description.sample
			industry_short_description = sandbox_youtube_channel.order('random()').first.industry_short_description.sample
			location_short_description = sandbox_youtube_channel.order('random()').first.location_short_description.sample
			other_short_description = sandbox_youtube_channel.order('random()').first.other_short_description.sample
			@channel_description = {client_short_description: client_short_description, industry_short_description: industry_short_description, location_short_description: location_short_description, other_short_description: other_short_description }
		end

		unless @locations.blank?
			location_items = @locations.map{|l| l.formatted_name(primary_region: true, primary_region_code: true)}.sample
		else
			location_items = sandbox_youtube_channel.order('random()').first.location.formatted_name(primary_region: true, primary_region_code: true) unless sandbox_youtube_channel.blank?
		end

		@channel_schema = {:entity => entity, :subject_component => subject, :location => location_items}
		@channel_name = @channel_schema.collect{|k,v| v}.join(' ').humanize

		unless sandbox_youtube_video.blank?
			product_component =	sandbox_youtube_video.order('random()').first.title_product_components.sample
			location_component = sandbox_youtube_video.order('random()').first.location.formatted_name(primary_region: true, primary_region_code: true) unless sandbox_youtube_video.order('random()').first.location.blank?
			subject_component = sandbox_youtube_video.order('random()').first.title_subject_components.sample
			entity_component = sandbox_youtube_video.order('random()').first.title_entity_components.sample
			@video_description = sandbox_youtube_video.order('random()').first.descriptions.sample
			@video_tags = sandbox_youtube_video.order('random()').first.tags
		end
		@video_title_schema = {:product => product_component, :location => location_component, :subject_component => subject_component, :entity => entity_component}
		@video_title = @video_title_schema.map{|k,v| v}.join(' ').humanize
	end

	def regenerate_channel_arts
		@channel_arts = Sandbox::YoutubeChannelImage.where(:sandbox_client_id => @sandbox_client.id, :image_type => Sandbox::YoutubeChannelImage::IMAGE_TYPES[:art]).order('random()').sample(10)
	end

	def regenerate_channel_icon
		@channel_icon = Sandbox::YoutubeChannelImage.where(:sandbox_client_id => @sandbox_client.id, :image_type => Sandbox::YoutubeChannelImage::IMAGE_TYPES[:icon]).order('random()').first
	end

	def regenerate_channel_name
		sandbox_youtube_channel = Sandbox::YoutubeChannel.where(:sandbox_client_id => @sandbox_client.id)
		youtube_setup = @sandbox_client.client.youtube_setups

		if !youtube_setup.blank?
			entity = youtube_setup.order('random()').first.business_channel_entity.sample
			subject = youtube_setup.order('random()').first.business_channel_subject.sample
		elsif !sandbox_youtube_channel.blank?
			entity = sandbox_youtube_channel.order('random()').first.title_entity_components.sample
			subject = sandbox_youtube_channel.order('random()').first.title_subject_components.sample
		end

		unless @locations.blank?
			location_items = @locations.map{|l| l.formatted_name(primary_region: true, primary_region_code: true)}.sample
		else
			location_items = sandbox_youtube_channel.order('random()').first.location.formatted_name(primary_region: true, primary_region_code: true) unless sandbox_youtube_channel.blank?
		end

		@channel_schema = {:entity => entity, :subject_component => subject, :location => location_items}
		@channel_name = @channel_schema.collect{|k,v| v}.join(' ').humanize
	end

	def regenerate_channel_tags
		sandbox_youtube_channel = Sandbox::YoutubeChannel.where(:sandbox_client_id => @sandbox_client.id)
		youtube_setup = @sandbox_client.client.youtube_setups

		if !youtube_setup.blank?
			@tags = youtube_setup.order('random()').first.other_business_channel_tags.map{|t| t.name}.shuffle.join(',')
		elsif !sandbox_youtube_channel.blank?
			@tags = sandbox_youtube_channel.order('random()').first.tags
		end
	end

	def regenerate_channel_descriptions
		youtube_setup = @sandbox_client.client.youtube_setups
		sandbox_youtube_channel = Sandbox::YoutubeChannel.where(:sandbox_client_id => @sandbox_client.id)

		unless sandbox_youtube_channel.blank?
			client_short_description = sandbox_youtube_channel.order('random()').first.client_short_description.sample
			industry_short_description = sandbox_youtube_channel.order('random()').first.industry_short_description.sample
			location_short_description = sandbox_youtube_channel.order('random()').first.location_short_description.sample
			other_short_description = sandbox_youtube_channel.order('random()').first.other_short_description.sample

			@channel_description = {
				client_short_description: client_short_description,
				industry_short_description: industry_short_description,
				location_short_description: location_short_description,
				other_short_description: other_short_description
			}
		end
	end

	def regenerate_video_thumbnail_image
		@video_thumbnails = Sandbox::YoutubeChannelImage.where(:sandbox_client_id => @sandbox_client.id, :image_type => Sandbox::YoutubeChannelImage::IMAGE_TYPES[:video]).order('random()').sample(9)
	end

	def regenerate_video_title
		sandbox_youtube_video = Sandbox::YoutubeVideo.where(:sandbox_client_id => @sandbox_client.id)

		unless sandbox_youtube_video.blank?
			product_component =	sandbox_youtube_video.order('random()').first.title_product_components.sample
			location_component = sandbox_youtube_video.order('random()').first.location.formatted_name(primary_region: true, primary_region_code: true)
			subject_component = sandbox_youtube_video.order('random()').first.title_subject_components.sample
			entity_component = sandbox_youtube_video.order('random()').first.title_entity_components.sample
		end
		@video_title_schema = {:product => product_component, :location => location_component, :subject_component => subject_component, :entity => entity_component}
		@video_title = @video_title_schema.map{|k,v| v}.join(' ').humanize
	end

	def regenerate_video_descriptions
		sandbox_youtube_video = Sandbox::YoutubeVideo.where(:sandbox_client_id => @sandbox_client.id)
		@video_description = sandbox_youtube_video.order('random()').first.descriptions.sample unless sandbox_youtube_video.blank?
	end

	def regenerate_video_tags
		sandbox_youtube_video = Sandbox::YoutubeVideo.where(:sandbox_client_id => @sandbox_client.id)
		@video_tags = sandbox_youtube_video.order('random()').first.tags unless sandbox_youtube_video.blank?
	end

	def video_info
		@video = Sandbox::Video.joins(:sandbox_client).
			where("sandbox_videos.id = ? AND sandbox_video_set_id = ? AND sandbox_clients.uuid = ?",
				params[:video_id],
				params[:video_blender_id],
				params[:client_uuid]).
			first
		render 'video_info', layout: false
	end

	def blend
		bl = Sandbox::BlendedVideo.where(session_id: session.id).first_or_create
		output = VideoTools::VideoBlender.new(videos: params[:videos]).blend()
		unless output.blank?
			bl.file = output
			bl.save!
			bl.reload
			output.close
			FileUtils.rm_rf output.path
		end
		video_path = bl.file.url(:original, timestamp: false)
		render json: {video: video_path}
	end

	def refresh_pattern
		@pattern = BlendingPattern.where(client_id: @sandbox_client.id).order('random()').first
	end

	def regenerate_youtube_channel
		@channel_icon = Sandbox::YoutubeChannelImage.where(:sandbox_client_id => @sandbox_client.id, :image_type => Sandbox::YoutubeChannelImage::IMAGE_TYPES[:icon]).order('random()').first
		sandbox_youtube_channel = Sandbox::YoutubeChannel.where(:sandbox_client_id => @sandbox_client.id)
		youtube_setup = @sandbox_client.client.youtube_setups

		if !youtube_setup.blank?
			entity = youtube_setup.order('random()').first.business_channel_entity.sample
			subject = youtube_setup.order('random()').first.business_channel_subject.sample
		elsif !sandbox_youtube_channel.blank?
			entity = sandbox_youtube_channel.order('random()').first.title_entity_components.sample
			subject = sandbox_youtube_channel.order('random()').first.title_subject_components.sample
		end
		unless @locations.blank?
			location_items = @locations.map{|l| l.formatted_name(primary_region: true, primary_region_code: true)}.sample
		else
			location_items = sandbox_youtube_channel.order('random()').first.location.formatted_name(primary_region: true, primary_region_code: true) unless sandbox_youtube_channel.blank?
		end

		@channel_schema = {:entity => entity, :subject_component => subject, :location => location_items}
		@channel_name = @channel_schema.collect{|k,v| v}.join(' ').humanize
	end

	def regenerate_youtube_video
		sandbox_youtube_video = Sandbox::YoutubeVideo.where(:sandbox_client_id => @sandbox_client.id)
		@video_description = sandbox_youtube_video.order('random()').first.descriptions.sample unless sandbox_youtube_video.blank?
		sandbox_youtube_video = Sandbox::YoutubeVideo.where(:sandbox_client_id => @sandbox_client.id)

		unless sandbox_youtube_video.blank?
			product_component =	sandbox_youtube_video.order('random()').first.title_product_components.sample
			location_component = sandbox_youtube_video.order('random()').first.location.formatted_name(primary_region: true, primary_region_code: true)
			subject_component = sandbox_youtube_video.order('random()').first.title_subject_components.sample
			entity_component = sandbox_youtube_video.order('random()').first.title_entity_components.sample
		end
		@video_title_schema = {:product => product_component, :location => location_component, :subject_component => subject_component, :entity => entity_component}
		@video_title = @video_title_schema.map{|k,v| v}.join(' ').humanize

		@channel_icon = Sandbox::YoutubeChannelImage.where(:sandbox_client_id => @sandbox_client.id, :image_type => Sandbox::YoutubeChannelImage::IMAGE_TYPES[:icon]).order('random()').first

		sandbox_youtube_channel = Sandbox::YoutubeChannel.where(:sandbox_client_id => @sandbox_client.id)
		youtube_setup = @sandbox_client.client.youtube_setups
		if !youtube_setup.blank?
			entity = youtube_setup.order('random()').first.business_channel_entity.sample
			subject = youtube_setup.order('random()').first.business_channel_subject.sample
		elsif !sandbox_youtube_channel.blank?
			entity = sandbox_youtube_channel.order('random()').first.title_entity_components.sample
			subject = sandbox_youtube_channel.order('random()').first.title_subject_components.sample
		end
		unless @locations.blank?
			location_items = @locations.map{|l| l.formatted_name(primary_region: true, primary_region_code: true)}.sample
		else
			location_items = sandbox_youtube_channel.order('random()').first.location.formatted_name(primary_region: true, primary_region_code: true) unless sandbox_youtube_channel.blank?
		end

		@channel_schema = {:entity => entity, :subject_component => subject, :location => location_items}
		@channel_name = @channel_schema.collect{|k,v| v}.join(' ').humanize
	end

	private
		def set_sandbox_client
			@sandbox_client = Sandbox::Client.find_by_uuid!(params[:client_uuid])
		end

		def init_blender_settings
			@video_set = @sandbox_client.video_sets.find(params[:id])
			video_regions = @video_set.get_videos.where(location_type: 'Geobase::Region').pluck(:location_id).compact
			video_localities = @video_set.get_videos.where(location_type: 'Geobase::Locality').pluck(:location_id).compact
			transition_regions = @video_set.get_transitions.where(location_type: 'Geobase::Region').pluck(:location_id).compact
			transition_localities = @video_set.get_transitions.where(location_type: 'Geobase::Locality').pluck(:location_id).compact

			@locations = []
			@locations |= Geobase::Region.where(id: video_regions | transition_regions)
			@locations |= Geobase::Locality.where(id: video_localities | transition_localities)
			@locations.sort!{|a,b|a.name.downcase <=> b.name.downcase}

			@channel_arts = Sandbox::YoutubeChannelImage.where(:sandbox_client_id => @sandbox_client.id, :image_type => Sandbox::YoutubeChannelImage::IMAGE_TYPES[:art]).order('random()').sample(10)
			@channel_icon = Sandbox::YoutubeChannelImage.where(:sandbox_client_id => @sandbox_client.id, :image_type => Sandbox::YoutubeChannelImage::IMAGE_TYPES[:icon]).order('random()').first
			@video_thumbnails = Sandbox::YoutubeChannelImage.where(:sandbox_client_id => @sandbox_client.id, :image_type => Sandbox::YoutubeChannelImage::IMAGE_TYPES[:video]).order('random()').sample(9)
		end

		def set_timeline_videos
			item = BlendingPattern.where(client_id: @sandbox_client.id).order('random()').first
			@pattern = item.value.split(',') unless item.blank?

			query = @video_set.get_videos
			query = query.where.not(video_file_name: nil).
				where("location_id = ? AND location_type = ?", @locations.first.id, @locations.first.class.name) if @locations.any?
			grouped_videos = query.group_by(&:video_type)
			unless grouped_videos['subject'].to_a.any?
				grouped_videos.merge!(@video_set.get_videos.with_video_type('subject').group_by(&:video_type))
			end
  		@timeline_videos = {}
			unless @pattern.blank?
				@pattern.each{|k| @timeline_videos[k] = grouped_videos[k] if grouped_videos.key?(k)}
			end
		end

		def sanitize_params
			system_dir = Rails.root.join('public')
			videos = []
			params[:videos].to_a.each do |v|
				videos << File.join(system_dir, v)
			end
			params[:videos] = videos
		end
end
