namespace :aae_templates do
	task import_project_spreadsheets: :environment do
		spreadsheets_dir = File.join('db','aae_project_spreadsheets','*.csv')
		csv_params = {col_sep: ';', skip_blanks: true}

		ActiveRecord::Base.transaction do
			Dir.glob([spreadsheets_dir]).each do |f|
				next if %w(.. .).include?(f)
				puts "Processing #{f}"
				projects = []
				current_project = nil
				CSV.foreach(f, csv_params) do |row|
					name = row[1].to_s
					unless name.strip.blank?
						projects << Templates::AaeProject.where("LOWER(name) LIKE '#{name.downcase}'").first_or_create do |project|
							project.name = name
							project.title = name.strip.humanize
							project.project_type = File.basename(f).to_s.split('.').first
						end
					end
				end

				i = 0
				CSV.foreach(f, csv_params) do |row|
					if !row[0].to_s.strip.blank? && !row[1].to_s.strip.blank?
						i += 1
						current_project = projects[i - 1]
					end

					#aae project images
					if !row[15].to_s.strip.blank? && !%w(0 -).include?(row[15].to_s.strip)
						image_size = row[16].to_s.split(/[x*]/)
						file_name = row[15].to_s.strip
						image_type = if(row[15].to_s.downcase.match('logo') != nil)
								:client_logo
							elsif row[17].to_s.downcase == 'location image'
								:location_image
							elsif row[17].to_s.downcase == 'client image'
								:client_image
							elsif row[17].to_s.downcase == 'subject image'
								:subject_image
							else
								nil
						end

						pi = Templates::AaeProjectImage.where(aae_project_id: current_project.id).where("LOWER(file_name) LIKE '#{file_name.downcase}'").first_or_initialize do |project_image|
							project_image.guid = SecureRandom.uuid
							project_image.file_name = file_name
							project_image.width = image_size[0]
							project_image.height = image_size[1]
							project_image.image_type = image_type
						end

						unless pi.new_record?
							pi.file_name = file_name
							pi.width = image_size[0]
							pi.height = image_size[1]
							pi.image_type = :client_logo if is_client_logo
						end

						current_project.aae_project_images << pi
					end

					#aae project texts
					unless row[22].to_s.blank?
						name = row[22].to_s
						value = row[23].to_s
						is_static = row[24].blank?
						text_type ||= row[24]
						matched_limit = value.match(/not more than\s+\d+\s+characters/)
						limit = matched_limit != nil ? matched_limit.to_a.first.match(/\d+/).to_a.first.to_i : nil
						encoded_value = Templates::AaeProjectText::encode_string(value)
						pt = Templates::AaeProjectText.where(aae_project_id: current_project.id).where("LOWER(name) LIKE '#{name.downcase}'").first_or_initialize do |project_text|
							project_text.guid = SecureRandom.uuid
							project_text.name = name
							project_text.value = value
							project_text.encoded_value = encoded_value
							project_text.text_limit = limit
							project_text.text_type = text_type
							project_text.is_static = is_static
						end

						unless pt.new_record?
							pt.value = value
							pt.encoded_value = encoded_value
							pt.text_limit = limit
							pt.text_type = text_type
							pt.is_static = is_static
						end
						current_project.aae_project_texts << pt
					end
				end

				projects.each { |p| p.save! }
			end
		end
	end

	task sync_with_project_files: :environment do
		Templates::AaeProject.all.each do |p|
			puts "processing #{p.project_dir} ..."
			if p.project_dir?
				if xml = Dir.glob("#{File.join(p.project_dir,'*.aepx')}").first
					xml_file = open(xml)
					p.xml = xml_file
					xml_file.close
					puts "xml uploaded"
				end
				if thumb = Dir.glob("#{File.join(p.project_dir,'*.jpg')}").first
					thumbnail_file = open(thumb)
					p.thumbnail = thumbnail_file
					thumbnail_file.close()
					puts "thumbnail uploaded"
				end
				if video = Dir.glob("#{File.join(p.project_dir,'*.mp4')}").first
					video_file = open(video)
					p.video = video_file
					video_file.close()
					puts "video uploaded"
				end
			else
				#puts "NOT OK #{p.project_dir}"
			end
			p.save!
		end
	end

	task :generate_thumbnails_for_rendered_videos, [:videos_dir] => :environment do |t, args|
		if File.directory? args.videos_dir
			Dir.glob("#{args.videos_dir}/**/*.mp4").each do |v|
				puts "processing #{v}"
				aae_project_id = File.basename(v).split("_")[1].split('-')[1].to_i
				thumbnail_file = v.gsub(".mp4",".jpg")
				Templates::AaeProject.dynamic_screenshot(aae_project_id, v).write(thumbnail_file)
				puts "created #{thumbnail_file}"
			end
		else
			puts "directory doesn't exist"
		end
	end
end
