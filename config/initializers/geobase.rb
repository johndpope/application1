Geobase::Country.class_eval do
	has_many :wordings, as: :resource
end

Geobase::Locality.class_eval do
	has_many :wordings, as: :resource
end

Geobase::Region.class_eval do
	has_many :wordings, as: :resource
end

Geobase::Landmark.class_eval do
	has_many :wordings, as: :resource
end

Geobase::Neighbourhood.class_eval do
	has_many :wordings, as: :resource
end
