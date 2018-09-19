class Templates::AaeProjectGenerator
	MIN_IMG_WIDTH = 800
	MIN_IMG_ASPECT_RATIO = 0.5

	TYPE_ALIASES = {
    introduction: :intro,
    collage: :col,
    bridge_to_subject: :b2sub,
    summary_points: :sumpoint,
    call_to_action: :c2act,
    ending: :end,
    credits: :cred,
    simple_transition: :strans,
    text_transition: :trans,
    image_text_transition: :itrans,
    likes_and_views: :likenview,
    social_networks: :snetwork
  }

	def initialize(options = {})
		options = {track_attributions: true, target: 'distribution', location: {type: "Locality"}}.merge options
		@aae_project = options[:aae_project]
		@source_video = options[:source_video]
		@client = options[:client]
		@product = options[:product]
		@target = options[:target]
		@track_attributions = options[:track_attributions]
		@dynamic_aae_project_id ||= options[:dynamic_aae_project_id]
		@blended_video_chunk_id ||= options[:blended_video_chunk_id]
		if [Geobase::Region, Geobase::Locality].include? options[:location].class
			@location = options[:location]
		else
			@location_type = options[:location][:type].titleize
			if !options[:location][:name].blank? || !options[:location][:state_name].blank?
				raise "Locality Name or State Name is not set"	if @location_type == "Locality"	&& (options[:location][:name].blank? || options[:location][:state].blank?)
				raise "County Name or State Name is not found"	if @location_type == "Region"	&& (options[:location][:name].blank? || options[:location][:state].blank?)
				@location = if @location_type == "Locality"
											Geobase::Locality.locality_and_primary_region_name(options[:location][:name], options[:location][:state])
										elsif @location_type == "Region"
											Geobase::Region.county(options[:location][:name], options[:location][:state])
										end
				raise "Location is not found" if @location.blank?
			end
		end
	end

	#TODO Refactor this method!!!!
	def generate
		ActiveRecord::Base.transaction do
			dynamic_aae_project = Templates::DynamicAaeProject.where(id: @dynamic_aae_project_id).first_or_create! do |dynamic_project|
				dynamic_project.target = @target
				dynamic_project.aae_project_id = @aae_project.id
				dynamic_project.client_product_id = @product.id
				dynamic_project.location = @location
				dynamic_project.source_video_id = @source_video.id unless @source_video.blank?
			end

			tmp_project_name = generate_project_name(dynamic_aae_project.try(:id))
			tmp_project_base_dir = tmp_project_name
			tmp_aae_templates_base_dir = '/tmp/broadcaster/aae_templates'
			tmp_project_dir = File.join(tmp_aae_templates_base_dir, tmp_project_base_dir)
			tmp_project_xml_file = File.join(tmp_project_dir, "#{tmp_project_name}.aepx")
			project_checksum_file = File.join(tmp_project_dir, 'project.checksum')
			tarred_project_filename = "#{SecureRandom.uuid}.tar"
			tarred_project_filepath = File.join(tmp_aae_templates_base_dir, tarred_project_filename)
			FileUtils.mkdir_p tmp_project_dir

			puts  Time.now.strftime("%Y-%m-%d %H:%M:%S")
			puts "AAE Project: #{@aae_project.id} / #{@aae_project.name}"
			puts "Client ID: #{@client.id} / #{@client.name}"
			puts "Product ID: #{@product.id} / #{@product.name}"
			puts "Source Video Id: #{@source_video.id} / #{@source_video.custom_title}" unless @source_video.blank?
			puts "Dynamic Project: #{tmp_project_name}"
			puts "Target: #{@target}"

			begin
				master_aepx = Nokogiri::XML(File.read(@aae_project.xml.path))
				#Force XPath to look for elements that are not in any namespace
				master_aepx.remove_namespaces!
				replaced_texts = []

				#dynamic texts
				@aae_project.dynamic_texts.group_by(&:text_type).each do |type, dynamic_texts|
					options = {aae_project: @aae_project,
						source_video: @source_video,
						client: @client,
						product: @product,
						location: @location,
						blended_video_chunk_id: @blended_video_chunk_id}

					texts = Templates::AaeProjectDynamicTextService.select_texts_for_aae_template(@aae_project, type, @source_video, location: @location, blended_video_chunk_id: @blended_video_chunk_id)
					i = 0
					dynamic_texts.each do |dt|
						if layers = master_aepx.xpath("//string[contains(text(), '#{dt.name}')]")
							new_encoded_value = Templates::AaeProjectText::encode_string(texts[i])
							layers.to_a.each do |layer|
								if btdk = layer.try(:parent).try(:at, 'btdk')
									btdk['bdata'] = btdk['bdata'].gsub(Templates::AaeProjectText.encode_string(dt.value), new_encoded_value)
									dynamic_aae_text = Templates::DynamicAaeProjectText.create!(aae_project_text_id: dt.id, dynamic_aae_project_id: dynamic_aae_project.id, value: texts[i])
									puts "generating text #{dt.value} => #{texts[i]} / #{new_encoded_value}"
								end
							end
						end
						i = (i+1 < texts.size ? i+1 : 0)
					end
				end

				#corrected static texts
				@aae_project.static_texts.where("corrected_value IS NOT null AND corrected_value != ''").each do |st|
					if layers = master_aepx.xpath("//string[contains(text(), '#{st.name}')]")
						new_encoded_value = Templates::AaeProjectText::encode_string(st.corrected_value)
						layers.to_a.each do |layer|
							if btdk = layer.try(:parent).try(:at, 'btdk')
								btdk['bdata'] = btdk['bdata'].gsub(Templates::AaeProjectText.encode_string(st.value), new_encoded_value)
								dynamic_aae_text = Templates::DynamicAaeProjectText.create!(aae_project_text_id: st.id, dynamic_aae_project_id: dynamic_aae_project.id, value: st.corrected_value)
							end
						end
					end
				end

				footage_folder_name = if File.directory?(File.join(@aae_project.project_dir, 'Footage'))
					'Footage'
				elsif File.directory?(File.join(@aae_project.project_dir, 'footage'))
					'footage'
				end

				unless footage_folder_name.blank?
					FileUtils.cp_r File.join(@aae_project.project_dir, footage_folder_name), tmp_project_dir
					footage_folder = File.join(tmp_project_dir, footage_folder_name)

					image_folder = if File.directory?(File.join(footage_folder, 'Images'))
						File.join(footage_folder, 'Images')
					elsif File.directory?(File.join(footage_folder, 'images'))
						File.join(footage_folder, 'images')
					end

					#TODO: refactor!
					unless image_folder.blank?
						# dynamic images
						# logo image

						cdsv = @source_video.client.client_donor_source_videos.where(recipient_source_video_id: @source_video.id).first
						donor_source_video ||= cdsv.try(:source_video)
						donor_product = if !donor_source_video.nil?
							donor_source_video.product
						elsif !@source_video.product.parent.nil?
							@source_video.product.parent
						end
						donor_client = donor_product.try(:client)

						#AAE Template with multiple logos for dealers
						if @aae_project.logo_images?
							certifying_manufacturer = !donor_client.nil? && @client.certifying_manufacturers.where(id: donor_client.id).exists? ? donor_client : nil

							@aae_project.logo_images.each do |logo|
								logo_image = if logo.image_type.client_logo?
														 		if @client.logo.present?
																	@client.logo
																elsif @product.logo.present?
																	@product.logo
																else
																	raise "AAE Template with ID=#{@aae_project.id} has logo placeholder, but current client or product doesn't have logo"
																end
														 else #client_secondary_logo
															 raise "AAE Template with Id=#{@aae_project.id} has badge logo placeholder, but current client is not dealer client" if donor_client.nil?
															 raise "AAE Template with Id=#{@aae_project.id} has badge logo placeholder, but current dealer is not certified member" if certifying_manufacturer.nil?
															 raise "AAE Template with Id=#{@aae_project.id} has badge logo placeholder, but current manufacturer doesn't have badge logo" if donor_client.badge_logo.nil?
															 donor_client.badge_logo
														 end
								raise "Client ##{@client.id} doesn't have logo(type=#{logo.image_type}) for AAE template ##{@aae_project.id}" if logo_image.blank?

								size = "#{logo.width}x#{logo.height}"
								puts "generating logo #{size}"
								tmp_logo_path = File.join(image_folder, logo.file_name)
								ImagemagickScripts::resize(logo_image.path, size).write(tmp_logo_path)

								file = open(tmp_logo_path)
								dynamic_aae_image = Templates::DynamicAaeProjectImage.create!(aae_project_image_id: logo.id,
									dynamic_aae_project_id: dynamic_aae_project.id,
									image_type: :client_logo,
									file: file)
								file.close
							end
						end

						# location images
						if @aae_project.location_images?
							rand_loc_images = Artifacts::Image.aae_project_generator_scope.with_location(@location, 5).order('RANDOM()').limit(@aae_project.location_images.count) #select images from top 5 cities sorted by population

							if rand_loc_images.to_a.size < @aae_project.location_images.count && @location.is_a?(Geobase::Locality)
								Geobase::Locality.where.not(id: @location.id).where(id: @location.ids_by_radius(20)).order('RANDOM()').each do |radius_loc|
									limit = @aae_project.location_images.count - rand_loc_images.to_a.size
									rand_loc_images = rand_loc_images + Artifacts::Image.aae_project_generator_scope.with_location(radius_loc).order('RANDOM()').limit(limit)

									break if @aae_project.location_images.count == rand_loc_images.to_a.size
								end
							end

							if rand_loc_images.any?
								i = 0
								@aae_project.location_images.each do |loc_image|
									size = "#{loc_image.width}x#{loc_image.height}"
									puts "generating location image #{size} #{rand_loc_images[i].file.path}"
									tmp_loc_image_path = File.join(image_folder, loc_image.file_name)
									rand_loc_images[i].crop(size).write(tmp_loc_image_path)

									file = open(tmp_loc_image_path)
									dynamic_aae_image = Templates::DynamicAaeProjectImage.create!(aae_project_image_id: loc_image.id,
										dynamic_aae_project_id: dynamic_aae_project.id,
										image_type: :location_image,
										file: file)
									file.close
									Attribution.create!(resource: dynamic_aae_image, component: rand_loc_images[i])

									i = (i+1 < rand_loc_images.size ? i+1 : 0)
								end
							else
								raise "Location doesn't have any image"
							end
						end

						#Select Subject Video images
						if @aae_project.subject_images?
							sub_img_count = @aae_project.subject_images.count
              #TODO change image selection from tag_list to artifacts_image_tag_list
							# Select Subject Video images
							rand_sub_images = Artifacts::Image.aae_project_generator_scope.with_tags(@source_video.tag_list).order('RANDOM()').limit(sub_img_count)

              #TODO change image selection from tag_list to artifacts_image_tag_list
							# Select Donor Subject Video image
							if !donor_source_video.nil? && rand_sub_images.size < sub_img_count
								rand_sub_images = rand_sub_images + Artifacts::Image.aae_project_generator_scope.with_tags(donor_source_video.tag_list).order('RANDOM()').limit(sub_img_count - rand_sub_images.size)
							end

							# Select Client images
							if rand_sub_images.size < sub_img_count
								rand_sub_images = rand_sub_images + Artifacts::Image.aae_project_generator_scope.where(client_id: @client.id).order('RANDOM()').limit(sub_img_count - rand_sub_images.size)
							end

							#Select Donor Client Images
							unless donor_source_video.nil?
								if rand_sub_images.size < sub_img_count
									rand_sub_images = rand_sub_images + Artifacts::Image.aae_project_generator_scope.where(client_id: donor_source_video.client.id).order('RANDOM()').limit(sub_img_count - rand_sub_images.size)
								end
							end

              used_stock_images = []
              #Select Stock images
              if rand_sub_images.size < sub_img_count
                used_stock_images = Artifacts::Image.stock_images_by_client(@client).order('RANDOM()').limit(sub_img_count - rand_sub_images.size)
                rand_sub_images = rand_sub_images + used_stock_images
              end

							raise "Current Subject Video with ID=#{@source_video.id} doesn't have enough images: #{rand_sub_images.size}/#{sub_img_count}" if rand_sub_images.size < sub_img_count

							i = 0
							@aae_project.subject_images.each do |sub_image|
								size = "#{sub_image.width}x#{sub_image.height}"
								puts "generating subject image #{size} #{rand_sub_images[i].file.path}"
								tmp_subj_image_path = File.join(image_folder, sub_image.file_name)
								rand_sub_images[i].crop(size).write(tmp_subj_image_path)

								file = open(tmp_subj_image_path)
								dynamic_aae_image = Templates::DynamicAaeProjectImage.create!(aae_project_image_id: sub_image.id,
									dynamic_aae_project_id: dynamic_aae_project.id,
									image_type: :subject_image,
									file: file)
								file.close
								Attribution.create!(resource: dynamic_aae_image, component: rand_sub_images[i])

								i = (i+1 < rand_sub_images.size ? i+1 : 0)
							end
						end

						# client images
						if @aae_project.client_images?
							#Select Client images
							rand_client_images = Artifacts::Image.aae_project_generator_scope.where(client_id: @client.id).order('RANDOM()').limit(@aae_project.client_images.count)

							#Select Donor Client Images
							unless donor_client.nil?
								if Artifacts::Image.aae_project_generator_scope.where(client_id: @client.id).count < 25
									rand_client_images = Artifacts::Image.aae_project_generator_scope.where("artifacts_images.client_id = ? OR artifacts_images.client_id = ?", @client.id, donor_client.id).order('RANDOM()').limit(@aae_project.client_images.count)
								end
							end

              # Select stock images
              if rand_client_images.size < @aae_project.client_images.count
                rand_client_images = rand_client_images + Artifacts::Image.where("id not in (?)", used_stock_images.present? ? used_stock_images.map(&:id) : [-1]).stock_images_by_client(@client).order('RANDOM()').limit(@aae_project.client_images.count - rand_client_images.size)
              end

							raise "Current client with ID=#{@client.id} doesn't have enough client images. #{@aae_project.client_images.count - rand_client_images.count} are missing" if rand_client_images.size < @aae_project.client_images.count

							i = 0
							@aae_project.client_images.each do |client_image|
								size = "#{client_image.width}x#{client_image.height}"
								puts "generating client image #{size} #{rand_client_images[i].file.path}"
								tmp_client_image_path = File.join(image_folder, client_image.file_name)
								rand_client_images[i].crop(size).write(tmp_client_image_path)

								file = open(tmp_client_image_path)
								dynamic_aae_image = Templates::DynamicAaeProjectImage.create!(aae_project_image_id: client_image.id,
									dynamic_aae_project_id: dynamic_aae_project.id,
									image_type: :client_image,
									file: file)
								file.close
								Attribution.create!(resource: dynamic_aae_image, component: rand_client_images[i])

								i = (i+1 < rand_client_images.size ? i+1 : 0)
							end
						end
					end
				end

				#replace original file paths with corresponding dynamic one
				master_aepx.xpath("//fileReference").each do |fr|
					dynamic_base_path = [@aae_project.dynamic_windows_base_project_path, tmp_project_base_dir].join('\\').to_s
					fr['fullpath'] = fr['fullpath'].gsub(/^.*?(?=\\Footage)/im, dynamic_base_path).gsub('\\','/').gsub('/','\\')
				end

				File.open(tmp_project_xml_file, 'w') do |f|
					f.write master_aepx.to_xml
				end

				#checksum calculation
				checksums = %x(md5deep -r -l "#{tmp_project_dir}").split("\n")
				File.open(project_checksum_file, 'w+'){|f|checksums.each{|s|f.puts(s)}}
				unless File.exist?(project_checksum_file)
					raise 'Failed to create project checksum file'
				end

				unless File.size?(project_checksum_file)
					raise 'Project checksum file is empty'
				end

				puts "Creating TAR archive of generated project"
				%x(cd "#{tmp_aae_templates_base_dir}" && tar -cf "#{tarred_project_filename}" -P "#{tmp_project_base_dir}")

				unless dynamic_aae_project.blank?
					dynamic_aae_project.tar_project = open(tarred_project_filepath)
					dynamic_aae_project.save!
				end
			rescue => exception
				raise exception
			ensure
				FileUtils.rm_rf tmp_project_dir
				FileUtils.rm_rf tarred_project_filepath
				puts "\n\n"
			end

			return dynamic_aae_project
		end
	end

	def generate_random_project(project_type)
		@aae_project = Templates::AaeProject.
			with_project_type(project_type).
			where('is_approved IS TRUE AND xml_file_name IS NOT NULL AND is_special IS NOT TRUE AND content_validation IS NOT FALSE AND content_lock IS NOT TRUE').
			order('RANDOM()').first
		generate
	end

	def self.bulk_generation(options = {target: 'sandbox', locations: {}})
		raise 'Please, specify at least one location (locality name + state name)' if options[:locations].blank?
		raise 'Please, specify client_id' if options[:client_id].blank?
		raise 'Please, specify product_id' if options[:product_id].blank?
	end

	def self.test_generation(options = {})
		options = {locality: "San Francisco", state: "California"}.merge options
		raise 'Please, specify client_id' if options[:client_id].blank?
		raise 'Please, specify product_id' if options[:product_id].blank?
		raise 'Please, specify aae project ids' if options[:aae_project_ids].blank?

		client = Client.find(options[:client_id])
		product = Product.find(options[:product_id])
		location = Geobase::Locality.locality_and_primary_region_name(options[:locality], options[:state])

		options[:aae_project_ids].each do |p_id|
			g = Templates::AaeProjectGenerator.new({locality: options[:locality],
				region1: options[:state],
				track_attributions: false,
				client: client,
				product: product,
				source_video: (SourceVideo.find(options[:source_video_id]) unless options[:source_video_id].blank?),
				aae_project: Templates::AaeProject.find(p_id)})
			g.generate
		end
	end

	def generate_project_name(dynamic_aae_project_id = nil)
		{dt: Time.now.strftime("%m%d%Y%H%M%S"),
			aaepid: @aae_project.id,
			dynaaepid: (dynamic_aae_project_id unless dynamic_aae_project_id.blank?)
		}.reject{|k,v|v.blank?}.map{|k,v|"#{k}-#{v}"}.join('_')
	end
end
