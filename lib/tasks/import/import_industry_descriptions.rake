namespace :db do
	namespace :seed do
	  task :import_industry_descriptions => :environment do
			puts 'Import industry descriptions task started.'
	    puts '1st part - Import industry descriptions task started.'
			ActiveRecord::Base.transaction do
				url = "http://naics.codeforamerica.org/v0/q?year=2012"
				response = %x(curl -X GET #{url})
				json = JSON.parse(response)

				json.each do |e|
					code = e['code'].to_s.try('split', '-').try(:first)
					code = '31' if code == '32' || code == '33'
					code = '44' if code == '45'
					code = '48' if code == '49'
					industry = Industry.where(code: code).first

					if industry.present?
						if e['description'].present?
              descriptions_list = e['description']
              descriptions_list.delete("The Sector as a Whole") if descriptions_list.include?("The Sector as a Whole")
              short_description = descriptions_list.first.gsub("31-33", "31").gsub("44-45", "44").gsub("48-49", "48").gsub(/Subsector (\w+),/, "").gsub(/subsector (\w+),/, "").gsub(/Sector (\w+),/, "").gsub(/sector (\w+),/, "").gsub(/Industry Group (\w+),/, "").gsub(/industry group (\w+),/, "").gsub(/U.S. Industry (\w+),/, "").gsub(/U.S. industry (\w+),/, "").gsub(/Industry (\w+),/, "").gsub(/industry (\w+),/, "").gsub("\nCross-references.\t\tEstablishments primarily engaged in", "").gsub("\t\t", "").gsub("--", " ").gsub("  ", " ").strip
							long_description = descriptions_list.join("\n").gsub("31-33", "31").gsub("44-45", "44").gsub("48-49", "48").gsub(/Subsector (\w+),/, "").gsub(/subsector (\w+),/, "").gsub(/Sector (\w+),/, "").gsub(/sector (\w+),/, "").gsub(/Industry Group (\w+),/, "").gsub(/industry group (\w+),/, "").gsub(/U.S. Industry (\w+),/, "").gsub(/U.S. industry (\w+),/, "").gsub(/Industry (\w+),/, "").gsub(/industry (\w+),/, "").gsub("\nCross-references.\t\tEstablishments primarily engaged in", "").gsub("\t\t", "").gsub("--", " ").gsub("  ", " ").strip
              if Wording.where("resource_id = ? AND resource_type = 'Industry' AND source = ? AND name = 'short_description'", industry.id, short_description).size == 0 && !(Utils.smart_sentences_count(short_description) == 1 && (short_description.include?("are classified") || short_description.include?("is classified")))
                industry.wordings << Wording.create(name: 'short_description', source: short_description, url: url)
              end
  						if Wording.where("resource_id = ? AND resource_type = 'Industry' AND source = ? AND name = 'long_description'", industry.id, long_description).size == 0 && !(Utils.smart_sentences_count(long_description) == 1 && (long_description.include?("are classified") || long_description.include?("is classified")))
  							industry.wordings << Wording.create(name: 'long_description', source: long_description, url: url)
  						end
						end

						if e['crossrefs'].present?
							e['crossrefs'].each do |crossref|
								description = crossref['text']
								code = crossref['code'].try('split', '-').try(:first)
								code = '31' if code == '32' || code == '33'
								code = '44' if code == '45'
								code = '48' if code == '49'

								if description.present?
                  description = description.gsub("31-33", "31").gsub("44-45", "44").gsub("48-49", "48").gsub(/Subsector (\w+),/, "").gsub(/subsector (\w+),/, "").gsub(/Sector (\w+),/, "").gsub(/sector (\w+),/, "").gsub(/Industry Group (\w+),/, "").gsub(/industry group (\w+),/, "").gsub(/U.S. Industry (\w+),/, "").gsub(/U.S. industry (\w+),/, "").gsub(/Industry (\w+),/, "").gsub(/industry (\w+),/, "").gsub("\nCross-references.\t\tEstablishments primarily engaged in", "").gsub("\t\t", "").gsub("--", " ").gsub("  ", " ").strip
                  if !(Utils.smart_sentences_count(description) == 1 && (description.include?("are classified") || description.include?("is classified")))
  									if Wording.where("resource_id = ? AND resource_type = 'Industry' AND source = ? AND name = 'short_description'", industry.id, description).size == 0
  										industry.wordings << Wording.create(name: 'short_description', source: description, url: url)
  									end
                    if Wording.where("resource_id = ? AND resource_type = 'Industry' AND source = ? AND name = 'long_description'", industry.id, description).size == 0
  										industry.wordings << Wording.create(name: 'long_description', source: description, url: url)
  									end
                  end
								end
							end
						end
					end
				end
			end
			puts '1st part - Import industry descriptions task finished.'

			puts '2nd part - Import industry descriptions task started.'
			ActiveRecord::Base.transaction do
				wordings = Wording.where("source like ?", 'See industry description%')

				wordings.each do |wording|
					code = wording.source.gsub('See industry description for ', '').gsub('industry ', '').gsub('.', '')
					ref_industry = Industry.where('code = ?', code).first

					if ref_industry.present?
						ref_wording = Wording.where("resource_id = ? AND resource_type = 'Industry' AND name = ?", ref_industry.id, wording.name).first

						if ref_wording.present?
							wording.source = ref_wording.source
							wording.save
						end
					end
				end
			end
			puts '2nd part - Import industry descriptions task finished.'

			puts '3rd part - Import industry descriptions task started.'
			ActiveRecord::Base.transaction do
				industry_ids = Wording.where("resource_type = 'Industry'").pluck(:resource_id)
				if industry_ids.present?
					industries = Industry.where("id not in (?)", industry_ids)
					industries.each do |industry|
						ref_industry = nil
						(1..9).each do |plus_code|
							code = industry.code + plus_code.to_s
							ref_industry = Industry.where(code: code).first
							break if ref_industry.present?
						end

						if ref_industry.present?
							wordings = Wording.where("resource_type = 'Industry' AND resource_id = ?", ref_industry.id)
              wordings.each do |wording|
							  industry.wordings << Wording.create(name: wording.name, source: wording.source, url: wording.url)
              end
						end
					end
				end
			end
			puts '3rd part - Import industry descriptions task finished.'
  	  puts 'Import industry descriptions task finished.'
	  end
	end
end
