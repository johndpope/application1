module SourceVideosHelper
	def loc_json(source_video)
		json = {country:{id: nil, name: nil},
			region1:{id: nil, name: nil},
			region2:{id: nil, name: nil},
			locality:{id: nil, name: nil}}
		if location = source_video.location
			if location.is_a? Geobase::Locality
				json[:country][:id] = location.primary_region.country.id
				json[:country][:name] = location.primary_region.country.name
				json[:region1][:id] = location.primary_region.id
				json[:region1][:name] = location.primary_region.name
				json[:region2][:id] = location.secondary_regions.to_a.first.try(:id)
				json[:region2][:name] = location.secondary_regions.to_a.first.try(:name)
				json[:locality][:id] = location.id
				json[:locality][:name] = location.name
			elsif location.is_a? Geobase::Region
				json[:country][:id] = location.country.id
				json[:country][:name] = location.country.name
				if location.level == 1
					json[:region1][:id] = location.id
					json[:region1][:name] = location.name
				elsif location.level == 2
					json[:region1][:id] = location.parent.id
					json[:region1][:name] = location.parent.name
					json[:region2][:id] = location.id
					json[:region2][:name] = location.name
				end
			elsif location.is_a? Geobase::Country
				json[:country][:id] = location.id
				json[:country][:name] = location.name
			end
		end

		json
	end
end
