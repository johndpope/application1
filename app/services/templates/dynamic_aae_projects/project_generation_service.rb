module Templates
	module DynamicAaeProjects
		class ProjectGenerationService
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

			AAE_TEMPLATES_BASE_DIR = File.join('tmp', 'broadcaster', 'aae_templates')

			class << self
				def generate_content(dynamic_aae_project_id, blended_video_chunk_id: nil)
					dynamic_aae_project = Templates::DynamicAaeProject.find(dynamic_aae_project_id)
					tmp_project_name = generate_project_name(dynamic_aae_project)
					tmp_project_base_dir = tmp_project_name
					tmp_project_dir = File.join(AAE_TEMPLATES_BASE_DIR, tmp_project_base_dir)
					tmp_project_xml_file = File.join(tmp_project_dir, "#{tmp_project_name}.aepx")
					project_checksum_file = File.join(tmp_project_dir, 'project.checksum')
					tarred_project_filename = "#{SecureRandom.uuid}.tar"
					tarred_project_filepath = File.join(AAE_TEMPLATES_BASE_DIR, tarred_project_filename)
					FileUtils.mkdir_p tmp_project_dir

					begin
						puts  Time.now.strftime("%Y-%m-%d %H:%M:%S")
						puts "AAE Project: #{dynamic_aae_project.aae_project.id} / #{dynamic_aae_project.aae_project.name}"
						puts "Client ID: #{dynamic_aae_project.client.id} / #{dynamic_aae_project.client.name}"
						puts "Product ID: #{dynamic_aae_project.product.id} / #{dynamic_aae_project.product.name}"
						puts "Source Video Id: #{dynamic_aae_project.source_video.id} / #{dynamic_aae_project.source_video.custom_title}"
						puts "Dynamic Project: #{tmp_project_name}"
						puts "Target: #{dynamic_aae_project.target}"

						ActiveRecord::Base.transaction do
							xml_project_doc = Nokogiri::XML(File.read(dynamic_aae_project.aae_project.xml.path))
							#Force XPath to look for elements that are not in any namespace
							xml_project_doc.remove_namespaces!

							raise "Cannot find template folder [#{dynamic_aae_project.aae_project.project_dir}] on disk" unless File.directory?(dynamic_aae_project.aae_project.project_dir)
							raise "Cannot find footage folder in template folder [#{dynamic_aae_project.aae_project.project_dir}]" if get_footage_folder_name(dynamic_aae_project).blank?

							#replaces text placeholders in xml with client's randomly selected strings
							replace_texts(dynamic_aae_project, xml_project_doc)
							#replaces image placeholders in project folder with client's/location's randomly selected images
							replace_images(dynamic_aae_project, xml_project_doc, tmp_project_dir)

							#replace original file paths with corresponding dynamic one
							xml_project_doc.xpath("//fileReference").each do |fr|
								dynamic_base_path = [dynamic_aae_project.aae_project.dynamic_windows_base_project_path, tmp_project_base_dir].join('\\').to_s
								fr['fullpath'] = fr['fullpath'].gsub(/^.*?(?=\\Footage)/im, dynamic_base_path).gsub('\\','/').gsub('/','\\')
							end

							File.open(tmp_project_xml_file, 'w+') do |f|
								f.write xml_project_doc.to_xml
							end

							#checksum calculation
							checksums = %x(md5deep -r -l "#{tmp_project_dir}").split("\n")
							File.open(project_checksum_file, 'w+'){|f|checksums.each{|s|f.puts(s)}}

							puts "Creating TAR archive from generated project"
							%x(cd "#{AAE_TEMPLATES_BASE_DIR}" && tar -cf "#{tarred_project_filename}" -P "#{tmp_project_base_dir}")

							File.open(tarred_project_filepath) do |f|
								dynamic_aae_project.tar_project = f
								dynamic_aae_project
								dynamic_aae_project.save!
							end
						end
					rescue	Exception => e
						raise e
					ensure
						FileUtils.rm_rf tmp_project_dir
						FileUtils.rm_rf tarred_project_filepath
					end
				end

				def get_project_options(file_name)
					if project_name = File.basename(file_name, ".aepx")
						options = project_name.split(/[\s_]/).map do |e|
							{e.split(/[:-]/)[0].to_sym => e.split(/[:-]/)[1]} unless e.split(/[:-]/)[0].blank?
						end.reject(&:blank?).reduce(Hash.new, :merge)
						res = {}
						aliases = {aaepid: :project,
							dynaaepid: :dynamic_project,
							aaeptype: :type,
							clientid: :client,
							prodid: :product,
							loctype: :location_type,
							locid: :location_id,
							sourcevideoid: :source_video,
							dt: :date,
							target: :target}
						aliases.each do |k,v|
							res[v] = options[k]
						end

						if ! res[:type].blank?
							if type = TYPE_ALIASES.key(res[:type].to_sym)
								res[:type] = type
							end
						end
						res
					end
				end

				private
					def generate_project_name(dynamic_aae_project)
						{dt: Time.now.strftime("%m%d%Y%H%M%S"),
							aaepid: dynamic_aae_project.aae_project.id,
							dynaaepid: dynamic_aae_project.id
						}.map{|k,v|"#{k}-#{v}"}.join('_')
					end

					def get_footage_folder_name(dynamic_aae_project)
						return (if File.directory?(File.join(dynamic_aae_project.aae_project.project_dir, 'Footage'))
							'Footage'
						elsif File.directory?(File.join(dynamic_aae_project.aae_project.project_dir, 'footage'))
							'footage'
						end)
					end

					def replace_texts(dynamic_aae_project, xml_project_doc, blended_video_chunk_id: nil)
						#dynamic texts
						dynamic_aae_project.aae_project.dynamic_texts.group_by(&:text_type).each do |type, dynamic_texts|
							texts = Templates::AaeProjectDynamicTextService.select_texts_for_aae_template(dynamic_aae_project.aae_project,
								type, dynamic_aae_project.source_video,
								location: dynamic_aae_project.location,
								blended_video_chunk_id: blended_video_chunk_id)
							i = 0
							dynamic_texts.each do |dt|
								if layers = xml_project_doc.xpath("//string[contains(text(), '#{dt.name}')]")
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
						dynamic_aae_project.aae_project.static_texts.where("corrected_value IS NOT null AND corrected_value != ''").each do |st|
							if layers = xml_project_doc.xpath("//string[contains(text(), '#{st.name}')]")
								new_encoded_value = Templates::AaeProjectText::encode_string(st.corrected_value)
								layers.to_a.each do |layer|
									if btdk = layer.try(:parent).try(:at, 'btdk')
										btdk['bdata'] = btdk['bdata'].gsub(Templates::AaeProjectText.encode_string(st.value), new_encoded_value)
										dynamic_aae_text = Templates::DynamicAaeProjectText.create!(aae_project_text_id: st.id, dynamic_aae_project_id: dynamic_aae_project.id, value: st.corrected_value)
									end
								end
							end
						end
					end

					def replace_images(dynamic_aae_project, xml_project_doc, tmp_project_dir)
						footage_folder_name = get_footage_folder_name(dynamic_aae_project)
						unless footage_folder_name.blank?
							FileUtils.cp_r File.join(dynamic_aae_project.aae_project.project_dir, footage_folder_name), tmp_project_dir
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

								cdsv = dynamic_aae_project.source_video.client.client_donor_source_videos.where(recipient_source_video_id: dynamic_aae_project.source_video.id).first
								donor_source_video ||= cdsv.try(:source_video)
								donor_product = if !donor_source_video.nil?
									donor_source_video.product
								elsif !dynamic_aae_project.source_video.product.parent.nil?
									dynamic_aae_project.source_video.product.parent
								end
								donor_client = donor_product.try(:client)

								#AAE Template with multiple logos for dealers
								if dynamic_aae_project.aae_project.logo_images?
									certifying_manufacturer = !donor_client.nil? && dynamic_aae_project.client.certifying_manufacturers.where(id: donor_client.id).exists? ? donor_client : nil

								dynamic_aae_project.aae_project.logo_images.each do |logo|
										logo_image = if logo.image_type.client_logo?
																 		if dynamic_aae_project.client.logo.present?
																			dynamic_aae_project.client.logo
																		elsif dynamic_aae_project.product.logo.present?
																			dynamic_aae_project.product.logo
																		else
																			raise "AAE Template with ID=#{dynamic_aae_project.aae_project.id} has logo placeholder, but current client or product doesn't have logo"
																		end
																 else #client_secondary_logo
																	 raise "AAE Template with Id=#{dynamic_aae_project.aae_project.id} has badge logo placeholder, but current client is not dealer client" if donor_client.nil?
																	 raise "AAE Template with Id=#{dynamic_aae_project.aae_project.id} has badge logo placeholder, but current dealer is not certified member" if certifying_manufacturer.nil?
																	 raise "AAE Template with Id=#{dynamic_aae_project.aae_project.id} has badge logo placeholder, but current manufacturer doesn't have badge logo" if donor_client.badge_logo.nil?
																	 donor_client.badge_logo
																 end
										raise "Client ##{dynamic_aae_project.client.id} doesn't have logo(type=#{logo.image_type}) for AAE template ##{dynamic_aae_project.aae_project.id}" if logo_image.blank?

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
								if dynamic_aae_project.aae_project.location_images?
									rand_loc_images = Artifacts::Image.aae_project_generator_scope.with_location(dynamic_aae_project.location, 5).order('RANDOM()').limit(dynamic_aae_project.aae_project.location_images.count) #select images from top 5 cities sorted by population

									if rand_loc_images.to_a.size < dynamic_aae_project.aae_project.location_images.count && dynamic_aae_project.location.is_a?(Geobase::Locality)
										Geobase::Locality.where.not(id: dynamic_aae_project.location.id).where(id: dynamic_aae_project.location.ids_by_radius(20)).order('RANDOM()').each do |radius_loc|
											limit = dynamic_aae_project.aae_project.location_images.count - rand_loc_images.to_a.size
											rand_loc_images = rand_loc_images + Artifacts::Image.aae_project_generator_scope.with_location(radius_loc).order('RANDOM()').limit(limit)

											break if dynamic_aae_project.aae_project.location_images.count == rand_loc_images.to_a.size
										end
									end

									if rand_loc_images.any?
										i = 0
										dynamic_aae_project.aae_project.location_images.each do |loc_image|
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
								if dynamic_aae_project.aae_project.subject_images?
									sub_img_count = dynamic_aae_project.aae_project.subject_images.count
                  #TODO change image selection from tag_list to artifacts_image_tag_list
									# Select Subject Video images
									rand_sub_images = Artifacts::Image.aae_project_generator_scope.with_tags(dynamic_aae_project.source_video.tag_list).order('RANDOM()').limit(sub_img_count)

                  #TODO change image selection from tag_list to artifacts_image_tag_list
									# Select Donor Subject Video image
									if !donor_source_video.nil? && rand_sub_images.size < sub_img_count
										rand_sub_images = rand_sub_images + Artifacts::Image.aae_project_generator_scope.with_tags(donor_source_video.tag_list).order('RANDOM()').limit(sub_img_count - rand_sub_images.size)
									end

									# Select Client images
									if rand_sub_images.size < sub_img_count
										rand_sub_images = rand_sub_images + Artifacts::Image.aae_project_generator_scope.where(client_id: dynamic_aae_project.client.id).order('RANDOM()').limit(sub_img_count - rand_sub_images.size)
									end

									#Select Donor Client Images
									unless donor_source_video.nil?
										if rand_sub_images.size < sub_img_count
											rand_sub_images = rand_sub_images + Artifacts::Image.aae_project_generator_scope.where(client_id: donor_source_video.client.id).order('RANDOM()').limit(sub_img_count - rand_sub_images.size)
										end
									end

                  used_stock_images = []
                  # Select Stock images
                  if rand_sub_images.size < sub_img_count
                    used_stock_images = Artifacts::Image.stock_images_by_client(dynamic_aae_project.client).order('RANDOM()').limit(sub_img_count - rand_sub_images.size)
                    rand_sub_images = rand_sub_images + used_stock_images
                  end

									raise "Current Subject Video with ID=#{dynamic_aae_project.source_video.id} doesn't have enough images: #{rand_sub_images.size}/#{sub_img_count}" if rand_sub_images.size < sub_img_count

									i = 0
									dynamic_aae_project.aae_project.subject_images.each do |sub_image|
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
								if dynamic_aae_project.aae_project.client_images?
									#Select Client images
									rand_client_images = Artifacts::Image.aae_project_generator_scope.where(client_id: dynamic_aae_project.client.id).order('RANDOM()').limit(dynamic_aae_project.aae_project.client_images.count)

									#Select Donor Client Images
									unless donor_client.nil?
										if Artifacts::Image.aae_project_generator_scope.where(client_id: dynamic_aae_project.client.id).count < 25
											rand_client_images = Artifacts::Image.aae_project_generator_scope.where("artifacts_images.client_id = ? OR artifacts_images.client_id = ?", dynamic_aae_project.client.id, donor_client.id).order('RANDOM()').limit(dynamic_aae_project.aae_project.client_images.count)
										end
									end

                  # Select stock images
                  if rand_client_images.size < dynamic_aae_project.aae_project.client_images.count
                    rand_client_images = rand_client_images + Artifacts::Image.where("artifacts_images.id not in (?)", used_stock_images.present? ? used_stock_images.map(&:id) : [-1]).stock_images_by_client(dynamic_aae_project.client).order('RANDOM()').limit(dynamic_aae_project.aae_project.client_images.count - rand_client_images.size)
                  end

									raise "Current client with ID=#{dynamic_aae_project.client.id} doesn't have enough client images. #{dynamic_aae_project.aae_project.client_images.count - rand_client_images.count} are missing" if rand_client_images.size < dynamic_aae_project.aae_project.client_images.count

									i = 0
									dynamic_aae_project.aae_project.client_images.each do |client_image|
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
					end
			end
		end
	end
end
