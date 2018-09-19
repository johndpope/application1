module WordingsHelper
	def init_form
		@wording = params[:action] == 'new' ? Wording.new : Wording.find(params[:id])
		params.each { |e| params.delete(:"#{e[0]}") if e[1] == '' }

		@is_country = (@wording.resource_type || params[:resource_type]) == 'Geobase::Country'
		@is_state = params[:template] == 'state'
		@is_county = params[:template] == 'county'
		@is_locality = (@wording.resource_type || params[:resource_type]) == 'Geobase::Locality'
		@is_landmark = (@wording.resource_type || params[:resource_type]) == 'Geobase::Landmark'
		@is_industry = (@wording.resource_type || params[:resource_type]) == 'Industry'

		if params[:action] == 'new'
			@wording.resource_id = params[:resource_id] if params[:resource_id].present?
			@wording.resource_type = params[:resource_type] if params[:resource_type].present?
		else
			resource = @wording.resource

			if resource.try('level').present?
				if resource.level == 1
					@is_state = true
					params[:template] = 'state'
				elsif resource.level == 2
					@is_county = true
					params[:template] = 'county'
				end
			end

			params[:resource_id] = @wording.resource_id
			params[:resource_type] = @wording.resource_type

			params[:country_id] = resource.country_id if @is_state

			if @is_county
				params[:country_id] = resource.country_id
				params[:state_id] = resource.parent_id
			end

			if @is_locality
				params[:state_id] = resource.primary_region_id
				params[:country_id] = resource.primary_region.country_id
			end

			if @is_locality
				params[:state_id] = resource.primary_region_id
				params[:country_id] = resource.primary_region.country_id
			end

			if @is_landmark
				params[:locality_id] = resource.locality_id
				params[:state_id] = resource.locality.primary_region_id
				params[:country_id] = resource.locality.primary_region.country_id
			end
		end

		params[:industry_id] = params[:resource_id] if params[:resource_id].present? && @is_industry
	end
end
