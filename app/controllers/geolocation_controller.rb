class GeolocationController < ApplicationController
  skip_before_filter :authenticate_admin_user!, :only => [:by_zip_code]

	def regions
		@regions = Geobase::Region.where(country_id: params[:country_id], level: 1).order(:name)
		render layout: false
	end

	def all_regions
		@regions = Geobase::Region.includes(:country)
			.by_id(params[:id])
			.by_name_field(params[:q])
			.order(:name)
			.references(:country)

		json = []

		@regions.each do |e|
			region_name = e.name
			level = e.level == 1 ? ' (State)' : ' (County)'
			region_name += level
			country_abbr = e.country.present? ? e.country.code : nil
			final_name = [region_name, country_abbr].compact.join(' · ')
			json << { id: e.id, text: "#{final_name} " }
		end

		render json: json
	end

	def localities
		@localities = Geobase::Locality.includes(primary_region: [:country])
			.by_id(params[:id])
			.by_primary_region_id(params[:region_id])
			.by_name(params[:q])
			.order('geobase_localities.name asc, geobase_countries.id asc')
			.references(primary_region: [:country])

		json = []

		@localities.each do |e|
			locality_name = e.name
			region_name = e.primary_region.present? ? e.primary_region.name : nil
			country_abbr = e.primary_region.present? && e.primary_region.country.present? ? e.primary_region.country.code : nil
			final_name = [locality_name, region_name, country_abbr].compact.join(' · ')
			json << { id: e.id, text: "#{final_name} ", population: e.population.to_i.to_s(:delimited) }
		end

		render json: json
	end

	def landmarks
		landmarks = Geobase::Landmark.joins('LEFT JOIN geobase_localities ON geobase_localities.id = geobase_landmarks.locality_id
			LEFT JOIN geobase_regions ON geobase_regions.id = geobase_localities.primary_region_id
			LEFT JOIN geobase_countries ON geobase_regions.country_id = geobase_countries.id')
			.where('geobase_landmarks.locality_id IS NOT NULL')
			.by_id(params[:id])
			.by_name(params[:q])
			.order('geobase_landmarks.name asc, geobase_countries.id asc')

		json = []

		landmarks.each do |e|
			landmark_name = e.name
			locality_name = e.try(:locality).try(:name)
			region_name = e.try(:locality).try(:primary_region).try(:name)
			country_abbr = e.try(:locality).try(:primary_region).try(:country).try(:code)
			final_name = [landmark_name, locality_name, region_name, country_abbr].compact.join(' · ')
			json << { id: e.id, text: "#{final_name} " }
		end

		render json: json
	end

	def top_localities
		query = 'geobase_localities.is_duplicate IS NOT TRUE'
		# query += ' AND geobase_localities.locality_type = 1 ' if params[:country].present? && params[:country].to_i == Geobase::Country.where("LOWER(name) = 'united states of america'").first.id
		query += ' AND geobase_regions.country_id = ?'
		@localities = Geobase::Locality.joins(:primary_region)
			.where(query, params[:country])
			.order('geobase_localities.population desc NULLS LAST').first(params[:localities_number].to_i)
		render json: @localities.map { |e| { id: e.id, text: "#{e.name}" } }
	end

	def localities_with_population_greater
		ap params
		query = 'geobase_localities.is_duplicate IS NOT TRUE'
		# query += ' AND geobase_localities.locality_type = 1 ' if params[:country].present? && params[:country].to_i == Geobase::Country.where("LOWER(name) = 'united states of america'").first.id
		query += ' AND geobase_localities.population > ? AND geobase_regions.country_id = ?'
		@localities= Geobase::Locality.joins(:primary_region)
			.where(query, params[:population].to_i, params[:country])
			.order('geobase_localities.population desc NULLS LAST')
		render json: @localities.map { |e| { id: e.id, text: "#{e.name}" } }
	end

	def cities
		query = if params[:ids].present?
			query = "geobase_localities.id in (#{params[:ids]})"
		else
			query = 'geobase_localities.is_duplicate IS NOT TRUE'
			# query += ' AND geobase_localities.locality_type = 1 ' if params[:country].present? && params[:country].to_i == Geobase::Country.where("LOWER(name) = 'united states of america'").first.id
			query += " AND geobase_localities.population > #{params[:population].to_i} " if params[:population].present? && params[:population].to_i > 0
			query += " AND geobase_localities.primary_region_id in (#{params[:states]}) " if params[:states].present? && params[:states] != 'null'
			query += " AND geobase_regions.country_id = #{params[:country].to_i}" if params[:country].present?
		end
		@localities = Geobase::Locality.joins(:primary_region).where(query).order('geobase_localities.population desc NULLS LAST')
		render json: @localities.map { |e| {id: e.id, text: "#{e.name}, #{e.try(:primary_region).try(:code).try(:split, '<sep/>').try(:first).to_s.gsub('US-', '')} (#{e.locality_type.present? ? e.locality_type : 'Unknown'})"} }
	end

	def counties
		query = "name <> '' AND level = 2 "

		if params[:ids].present?
			query += " AND id in (#{params[:ids]})"
		else
			region_ids = []
			region_ids = Geobase::Locality.joins(:primary_region)
				.select('primary_region_id')
				.where('geobase_regions.level = 2')
				.group('primary_region_id')
				.having('sum(population) > ?', params[:population].to_i)
				.pluck(:primary_region_id) if params[:population].present? && params[:population].to_i > 0
			query += " AND parent_id in (#{params[:states]}) " if params[:states].present? && params[:states] != 'null'
			query += " AND country_id = #{params[:country].to_i}" if params[:country].present?
			query += " AND id in (#{region_ids.to_s.gsub(/(\[|\])/, '')})" if region_ids.present?
		end

		@counties = Geobase::Region.where(query).order(:name)
		render json: @counties.map { |e| { id: e.id, text: "#{e.name}, #{e.try(:parent).try(:code).try(:split, '<sep/>').try(:first).to_s.gsub('US-', '')}" } }
	end

	def states
		query = 'level = 1'
		query += " AND country_id = #{params[:country].to_i}" if params[:country].present?
		@states = Geobase::Region.where(query).order(:name)
		render json: @states.map { |e| { id: e.id, text: "#{e.name}" } }
	end

	def by_zip_code
		code = params[:zip_code][0..4]
		zip_code = Geobase::ZipCode.where('code = ?', code).first

		locality = if zip_code
			locality = zip_code.localities.first
		else
			nil
		end

		render json: { locality: locality.try(:name).to_s, region: locality.try(:primary_region).try(:name).to_s, country: locality.try(:primary_region).try(:country).try(:name).to_s }
	end
end
