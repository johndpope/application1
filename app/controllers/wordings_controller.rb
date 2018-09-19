class WordingsController < ApplicationController
	include WordingsHelper
	before_action :init_form, only: [:new, :edit]

	before_action :set_wording, only: [:show, :edit, :update, :destroy]
	WORDING_DEFAULT_LIMIT = 25

	def index
		params[:limit] = WORDING_DEFAULT_LIMIT unless params[:limit].present?

		if params[:filter].present?
			params[:filter][:order] = 'created_at' unless params[:filter][:order].present?
			params[:filter][:order_type] = 'asc' unless params[:filter][:order_type].present?
		else
			params[:filter] = { order: 'updated_at', order_type: 'desc' }
		end

    order_by = if params[:filter][:order] == 'chars'
      order_by = 'LENGTH(wordings.source)'
    else
      params[:filter][:order]
    end

		@wordings = Wording.by_id(params[:id])
			.by_source(params[:source])
			.by_name(params[:name])
			.by_url(params[:url])
			.by_admin_user_id(params[:admin_user_id])
			.by_updated_by_id(params[:updated_by_id])
			.by_resource_id(params[:resource_id])
			.by_resource_type(params[:resource_type])
			.page(params[:page]).per(params[:limit])
			.order(order_by + ' ' + params[:filter][:order_type])
	end

	def geo_index
		@defaults = { country: [1, %w()], state: [3038, %w(capital largest_city largest_metropolitan_area motto slogan song spoken_languages sport_teams dance amphibian bird fish animal insect flower tree fruit colors)], county: [3058, %w(metropolitan_statistical_area county_seat largest_city)], locality: [32589, %w(name locality_type code nicknames population)], landmark: [851, %w()] }

		if @has_type = params[:type].present?
			params[:resource_type] = 'Geobase::' + params[:type].capitalize
			params[:resource_id] = params[(params[:type] + '_id').to_sym]
			@wording = Wording.where('resource_type IS NOT NULL AND resource_type = ? AND resource_id = ?', params[:resource_type], params[:resource_id])
			@resource = @wording.try('first').try('resource')
			@list_of_names = @wording.select(:name).distinct.pluck(:name)
		end

		render 'wordings/geo/index'
	end

	def geo_show
	end

	def new
	end

	def edit
	end

	def create
		@wording = Wording.new(wording_params)
		@wording.admin_user = current_admin_user if current_admin_user.present?

		respond_to do |format|
			if @wording.save
				url = if params[:submit_next].present?
					format.html { redirect_to new_wording_path(resource_id: @wording.resource_id, resource_type: @wording.resource_type, name: @wording.name), notice: 'Wording was successfully created.' }
				else
					format.html { redirect_to wordings_path, notice: 'Wording was successfully created.' }
				end

				format.json { render redirect_to wordings_path, status: :created, location: @wording }
			else
				format.html { render action: 'new' }
				format.json { render json: @wording.errors, status: :unprocessable_entity }
			end
		end
	end

	def add_batch
		data = JSON.parse(params[:json_object])

		admin_user = current_admin_user if current_admin_user.present?
		response = { status: 200 }
		wordings_array = []
		wordings_errors = {}
		valid_all = true

		data['group'].each do |e|
			wording = Wording.new(
				resource_id: data['resource_id'],
				resource_type: data['resource_type'],
				name: e['name'],
				source: e['source'],
				url: URI.escape(data['url']),
				admin_user: admin_user
			)

			wordings_array << wording

			if !wording.valid?
				valid_all = false
				wordings_errors.merge!(wording.errors.messages)
			end
		end

		if valid_all
			wordings_array.each { |w| w.save }

			if ['Geobase::Region', 'Geobase::Locality'].include?(data['resource_type'])
				resource = wordings_array.first.resource
				resource.code = data['code'].to_s.split(",").collect(&:strip).uniq.join('<sep/>')
				resource.nicknames = data['nicknames'].to_s.split(",").collect(&:strip).uniq.join('<sep/>')
				resource.region_attributes = Geobase::RegionAttributes.build(data['region_attributes']) if data['region_attributes'].present?
				resource.save
			end
      if data['resource_type'] == 'Industry'
        resource = wordings_array.first.resource
        resource.tag_list = data['wording_industry_tag_list']
        resource.save
      end
		else
			response = { status: :unprocessable_entity, message: wordings_errors }
		end

    if response[:status] == 200
      response[:url] = wordings_path
    end

		respond_to do |format|
			format.json { render json: response, status: response[:status] }
		end
	end

	def update_batch
		data = JSON.parse(params[:json_object])
		admin_user = current_admin_user if current_admin_user.present?
		response = { status: 200 }

		wording = Wording.find_by_id(data['id'])

		data['group'].each do |e|
			wording.update_attributes(
				resource_id: data['resource_id'],
				resource_type: data['resource_type'],
				name: e['name'],
				source: e['source'],
				url: data['url'],
				updated_by: admin_user
			)

			response = { status: :unprocessable_entity, message: wording.errors } if !wording.save
		end

		if ['Geobase::Region', 'Geobase::Locality'].include?(data['resource_type'])
			resource = wording.resource
			resource.code = data['code'].to_s.split(",").collect(&:strip).uniq.join('<sep/>')
			resource.nicknames = data['nicknames'].to_s.split(",").collect(&:strip).uniq.join('<sep/>')
			resource.region_attributes = Geobase::RegionAttributes.build(data['region_attributes']) if data['region_attributes'].present?
			resource.save
		end

    if data['resource_type'] == 'Industry'
      resource = wording.resource
      resource.tag_list = data['wording_industry_tag_list']
      resource.save
    end

    if response[:status] == 200
      next_wording = Wording.where(resource_id: data['resource_id'], resource_type: data['resource_type']).order(updated_at: :asc).first
      response[:url] = !next_wording.present? || next_wording.id == wording.id ? wordings_path : edit_wording_path(next_wording)
    end

		respond_to do |format|
			format.json { render json: response, status: response[:status] }
		end
	end

	def update
		@wording.updated_by = current_admin_user if current_admin_user.present?

		respond_to do |format|
			if @wording.update(wording_params)
				format.html { redirect_to wordings_path, notice: 'Wording was successfully updated.' }
				format.json { head :no_content }
			else
				format.html { render action: 'edit' }
				format.json { render json: @wording.errors, status: :unprocessable_entity }
			end
		end
	end

	def destroy
		@wording.destroy

		respond_to do |format|
			format.html { redirect_to :back, notice: 'Wording was successfully deleted.' }
			format.json { head :no_content }
		end
	end

	def resource_template
		unless params[:filter].present?
			params[:template] = params[:resource_type].gsub('Geobase::', '').downcase if !params[:template].present? && params[:resource_type].present?

			if params[:template] != 'industry'
				# Country
				if params[:resource_id].present?
					params[:country_id] = params[:resource_id] if params[:template] == 'country'
					params[:state_id] = params[:resource_id] if params[:template] == 'state'
					params[:county_id] = params[:resource_id] if params[:template] == 'county'
					params[:locality_id] = params[:resource_id] if params[:template] == 'locality'
					params[:landmark_id] = params[:resource_id] if params[:template] == 'landmark'
				end

				params[:country_id] = Geobase::Country.find_by_code('US').id unless params[:country_id].present?

				@countries = Geobase::Country.all.order(name: :asc)
        @search_country = @countries.find_by_id(params[:country_id])
				@country_by_id = @search_country.try(:id)

				# State
				if params[:country_id].present?
					@state = Geobase::Region.where('country_id = ? AND level = 1', params[:country_id]).order('level ASC NULLS LAST, name ASC')
					@search_state = (params[:state_id].present?) ? @state.find_by_id(params[:state_id]) : nil
				end

				if params[:state_id].present?
					# County
					@county = Geobase::Region.where('country_id = ? AND level = 2 AND parent_id = ?', params[:country_id], params[:state_id]).order('level ASC NULLS LAST, name ASC')
					@search_county = (params[:county_id].present?) ? @county.find_by_id(params[:county_id]) : nil

					region_ids = Geobase::Region.where('country_id = ? AND parent_id = ?', params[:country_id], params[:state_id]).pluck(:id)
					region_ids << params[:state_id]

					# Locality
					@localities = Geobase::Locality.where('primary_region_id in (?)', region_ids).order('locality_type ASC NULLS LAST, name ASC')
					@search_locality = Geobase::Locality.find_by_id(params[:locality_id])

					@region_attributes = if params[:template] == 'state'
						%w(capital largest_city largest_metropolitan_area motto slogan song spoken_languages sport_teams dance amphibian bird fish animal insect flower tree fruit colors)
					elsif params[:template] == 'county'
						%w(metropolitan_statistical_area county_seat largest_city)
					end
				end

				# Landmark
				if params[:locality_id].present?
					@landmarks = Geobase::Landmark.where('locality_id = ?', params[:locality_id]).order(name: :asc)
					@landmark_by_id = @landmarks.find_by_id(params[:resource_id]).try(:id)
				end
      else
        params[:industry_id] = params[:resource_id]
        @search_industry = Industry.find_by_id(params[:industry_id])
			end

			respond_to do |format|
				format.html { render partial: "wordings/types/#{params[:template]}", layout: false }
			end
		else
			params[:filter] = params[:filter].try(:downcase)

			respond_to do |format|
				format.html { render partial: 'wordings/types/filter', layout: false }
			end
		end
	end

	def legend
		@wording = Wording.find(params[:id])

		respond_to do |format|
			format.html { render 'legend', layout: false, locals: { wording: @wording } }
		end
	end

	def duplicates
		@wording = Wording.where('source like ?', "%#{params[:text]}%").first

		respond_to do |format|
			format.html { redirect_to wordings_url }
			format.json { render :json => @wording.to_json }
		end
	end

	def history
		@wordings = Wording.by_resource_id(params[:resource_id]).by_resource_type(params[:resource_type]).by_name(params[:name]).order("wordings.updated_at DESC")

		respond_to do |format|
			format.html { render partial: 'wordings/list_of_wordings', layout: false }
		end
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_wording
			@wording = Wording.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def wording_params
			params.require(:wording).permit!
		end
end
