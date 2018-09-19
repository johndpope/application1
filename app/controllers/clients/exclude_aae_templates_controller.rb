class Clients::ExcludeAaeTemplatesController < ApplicationController
	include ApplicationHelper
	before_action :set_client
	before_action :set_project_types, except: %w(update_exclusion_settings)
	before_action :set_templates, except: %w(update_exclusion_settings)
	before_action :set_opt_out_statistics, except: %w(update_exclusion_settings)

	ITEMS_LIMIT = 25

	def index
	end

	def create
		@aae_project = Templates::AaeProject.find(params[:templates_aae_project_id])
		@opt_out = Templates::AaeProjectOptOut.create! opt_out_params
	end

	def destroy
		@opt_out = Templates::AaeProjectOptOut.find(params[:id])
		@aae_project = Templates::AaeProject.find(@opt_out.templates_aae_project_id)
		@opt_out.destroy!		
	end

	def update_exclusion_settings
		ActiveRecord::Base.transaction do
			@client.update params.require(:client).permit(:ignore_special_templates)
		end
	end

	private
		def set_client
			@client = Client.find(params[:client_id])
		end

		def set_project_types
			@types = []
			video_type_name_grouped_options(false, false).map{|k,v|v}.each{|type_group| type_group.each{|type| @types << type}}
			@current_type = params[:project_type] || @types.first[1]
		end

		def set_templates
			query = Templates::AaeProject.where(client_id: nil, product_id: nil, source_video_id: nil)
			query = query.with_project_type(@current_type) unless @current_type.blank?
			query = query.page(params[:page]).per(ITEMS_LIMIT) if params[:action] == 'index'
			@templates =  query
			@opt_outs = Templates::AaeProjectOptOut.
				where(client_id: @client.id, templates_aae_project_id: @templates.pluck(:id)).
				map{|o| {id: o.id, templates_aae_project_id: o.templates_aae_project_id}}
		end

		def set_opt_out_statistics
			 res = Templates::AaeProject.unscoped.
			 	select(%Q[templates_aae_projects.project_type,
					(SELECT COUNT(aaep1.project_type)
						FROM templates_aae_projects AS aaep1
						WHERE aaep1.project_type = templates_aae_projects.project_type) AS total,
					(SELECT COUNT(aaep2.project_type)
						FROM templates_aae_project_opt_outs AS opt_outs
						INNER JOIN templates_aae_projects aaep2 ON opt_outs.templates_aae_project_id=aaep2.id
						WHERE aaep2.project_type = templates_aae_projects.project_type AND opt_outs.client_id = #{@client.id}) AS excluded_count]).
				group('templates_aae_projects.project_type').
				map{|t|{"#{t.project_type}" => {"total_count" => t.total, "excluded_count" => t.excluded_count, "included_count" => (t.total - t.excluded_count)}}}
				@opt_out_statistics = Hash[*res.collect{|h| h.to_a}.flatten]
		end

		def opt_out_params
			params.permit :id, :client_id, :templates_aae_project_id
		end
end
