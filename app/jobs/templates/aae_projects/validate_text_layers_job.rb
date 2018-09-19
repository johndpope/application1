module Templates
	module AaeProjects
		ValidateTextLayersJob = Struct.new(:aae_project_id) do
			def perform
				ActiveRecord::Base.transaction do
					aae_project = Templates::AaeProject.find(aae_project_id)
					if aae_project.xml.blank?
						aae_project.aae_project_texts.each do |pt|
							pt.name_presents = false
							pt.value_presents = false
							pt.save!
						end
					else
						texts_flags = []

						master_aepx = Nokogiri::XML(File.read(aae_project.xml.path))
						#Force XPath to look for elements that are not in any namespace
						master_aepx.remove_namespaces!

						aae_project.aae_project_texts.each do |pt|
			        text_flags = {id: pt.id, name: false, value: false}
							escaped_str = "'#{pt.name.split("'").join("', \"'\", '")}', ''";
			        if layers = master_aepx.xpath("//string[contains(text(), concat(#{escaped_str}))]")
			          text_flags[:name] = true
			          layers.to_a.each do |layer|
			            if btdk = layer.try(:parent).try(:at, 'btdk')
			              if btdk['bdata'].include? Templates::AaeProjectText.encode_string(pt.value.gsub("\n",''))
			                text_flags[:value] = true
			              end
			            end
			          end
			        end
			        pt.name_presents = text_flags[:name]
							pt.value_presents = text_flags[:value]
							pt.save!
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
