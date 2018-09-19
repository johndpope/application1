crumb :geo do
	link 'GEO', geo_path
end

['country', 'state', 'county', 'locality', 'landmark'].each do | t |
	crumb t.to_sym do
		link t.capitalize
		parent :geo
	end
end
