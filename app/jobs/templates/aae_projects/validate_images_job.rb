module Templates
	module AaeProjects
		ValidateImagesJob = Struct.new(:aae_project_id) do
			def perform
				ActiveRecord::Base.transaction do
					aae_project = Templates::AaeProject.find(aae_project_id)
					if aae_project.xml.blank?
						aae_project.aae_project_images.each do |pi|
							pi.name_presents = false
							pi.save!
						end
					else
						xml_file = nil

						master_aepx = Nokogiri::XML(File.read(aae_project.xml.path))
						#Force XPath to look for elements that are not in any namespace
						master_aepx.remove_namespaces!

						aae_project.aae_project_images.each do |pi|
							if file_references = master_aepx.xpath("//fileReference")
								name_presents = false
								file_references.each do |fr|
									if pi.file_name == File.basename(fr['fullpath'].gsub('\\','/'))
										name_presents = true
										break
									end
								end
								pi.name_presents = name_presents
								pi.save!
							end
						end

					end
				end
			end

			def max_attempts
	      5
	    end

			def max_run_time
				240 #seconds
			end

	    def reschedule_at(current_time, attempts)
	      current_time + 1.hours
	    end

			def success(job)
				ActiveRecord::Base.transaction do
					aae_template = Templates::AaeProject.find(aae_project_id)
					texts_valid = !aae_template.aae_project_texts.where("(name_presents IS FALSE OR value_presents IS FALSE)").exists?
					images_valid = !aae_template.aae_project_images.where("name_presents IS FALSE").exists?
					aae_template.content_lock = nil
					aae_template.content_validation = (texts_valid && images_valid)
					aae_template.save!
				end
			end
		end
	end
end
